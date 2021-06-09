<#
.SYNOPSIS
    Triggers the creation of an image via the provided packer script.
.NOTES
    Requires az cli to run
#>

Param(
    # Specifies an azure location for the image
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    # Specifies the name of a Shared Image Gallery to store the created image in
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$GalleryName,

    # Specifies the name of the resource group containing tosca service resources.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicesResourceGroupName,

    # Specifies the name of a resource group used to deploy temporary resources to.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ClientResourceGroupName,
    
    # Specifies the URI to an installation executable for Tricentis Tosca.
    [Parameter(Mandatory=$true)]
    [string]$ToscaSetupUri,

    # Specifies the URI to an installation executable for Tosca Server. Only needed if installtype is ToscaServer.
    [Parameter(Mandatory=$false)]
    [string]$ToscaServerSetupUri,

    # Specifies the URI to an patch executable for Tosca Server. Only needed if installtype is ToscaServer.
    [Parameter(Mandatory=$false)]
    [string]$ToscaServerPatchUri,

    # Specifies service principal ID used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalId,

    # Specifies service principal secret used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalSecret,

    # Specifies the ID of a tenant used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    # Specifies the path to a packer file to build the image.
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "The provided packer file $_ does not exist." 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The provided packer file $_ must be a file."
        }
        return $true
    })]
    [string]$PackerScriptPath,

    # Specifies password for the packer windows account. Only used during image creation. Can be set for debug reason, otherwise the script will auto-generate it
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$InstallPassword,

    # Specifies the publisher of the created image.
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$ImagePublisher = "Tricentis",

    # Specifies the offer of the created image.
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$ImageOffer = "ToscaCloudEnvironment",

    # Specifies the version of the created image. Specified version needs to adhere to the semver 2.0 standard with 3 digits and without labels or extensions.
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        $parsed = [version]::Parse($_)

        if(-1 -ne $parsed.Revision){
            throw "Please provide a 3-digit version number as image version."
        }

        return $true
    })]
    [string]$ImageVersion,

    # Specifies the installtype for Tricentis Tosca. Valid values are 'ToscaCommander', 'DexAgent', or 'ToscaServer'.
    [Parameter(Mandatory=$true)]
    [ValidateSet("ToscaCommander","DexAgent","ToscaServer","Win10Base")]
    [string]$ToscaSetupType,

    # Specifies the Tosca environment vnet. Will be auto-discovered if no value is provided.
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$ToscaServicesVnet
)

Write-Output "Getting things ready."

# verify that all files needed for the deployment are available
$functionsPath = "$PSScriptRoot\..\..\shared\functions.ps1"
if(-not (Test-Path -Path $functionsPath)){
	throw "Could not find $functionsPath"
}
. $functionsPath

if($ToscaSetupType -eq "ToscaServer" -and [string]::IsNullOrWhiteSpace($ToscaServerSetupUri)){
    throw "Parameter ToscaServerSetupPath needs to be provided if ToscaSetupType is set to ToscaServer."
}

az login --service-principal -u $ServicePrincipalId -p $ServicePrincipalSecret --tenant $TenantId | ConvertFrom-Json

# Display warning and exit script if az cli is not logged in or not able to connect to subscription
az account show > $null
if($? -eq $false){
    return
}

Write-Output "Getting service principal."
$subscriptionId = (az account show | ConvertFrom-Json).id

Write-Output "Checking image gallery."
$definitions = az sig image-definition list --resource-group $ServicesResourceGroupName --gallery-name $GalleryName | ConvertFrom-Json
$existingDefinition = $definitions | Where-Object {$_.name -eq $ToscaSetupType }

if($null -eq $existingDefinition){
    Write-Output "Creating image definition with the following parameters"
    Write-Output "Name: $ToscaSetupType"
    Write-Output "Publisher: $ImagePublisher"
    Write-Output "Offer: $ImageOffer"
    Write-Output "SKU: $ToscaSetupType"

    az sig image-definition create `
        --location $Location `
        --resource-group $ServicesResourceGroupName `
        --gallery-name $GalleryName `
        --gallery-image-definition $ToscaSetupType `
        --publisher $ImagePublisher `
        --offer $ImageOffer `
        --sku $ToscaSetupType `
        --os-type "Windows" `
        --os-state "generalized" `
        --hyper-v-generation V2
}

# For packer to be able to download setups, each setup url needs to contain a sas
Write-Output "Configuring storage account."
try {
    $ToscaSetup = (ParseStorageAccountUri -Uri $ToscaSetupUri)
    $toscaSas = GenerateSaSas -ResourceGroup $ServicesResourceGroupName -StorageAccount $toscaSetup.Name -ValidFor 2
    $toscaBlob = "$ToscaSetupUri`?$toscaSas"

    if(-not [string]::IsNullOrWhiteSpace($ToscaServerSetupUri)){
        $ToscaServerSetup = (ParseStorageAccountUri -Uri $ToscaServerSetupUri)
        $toscaServerSas = GenerateSaSas -ResourceGroup $ServicesResourceGroupName -StorageAccount $ToscaServerSetup.Name -ValidFor 2
        $toscaServerBlob = "$ToscaServerSetupUri`?$toscaServerSas"
    }

    if(-not [string]::IsNullOrWhiteSpace($ToscaServerPatchUri)){
        $serverPatch = ParseStorageAccountUri -Uri $ToscaServerPatchUri
        $serverPatchSas = GenerateSaSas -ResourceGroup $ServicesResourceGroupName -StorageAccount $serverPatch.Name -ValidFor 2
        $serverPatchBlob = "$ToscaServerPatchUri`?$serverPatchSas"
    }
}
catch {
    Write-Error $($_.Exception)
    az logout
    return
}

Write-Output "Getting public IP."
try {
	$publicIP = GetExternalIPAddress
}
catch {
    Write-Output "An Error occurred while evaluating the public IP address of this host: $($_.Exception)"
    az logout
	return
}

if([string]::IsNullOrWhiteSpace($ToscaServicesVnet)){
    Write-Output "Discovering vnet."
    try {
        $vnet = DiscoverAzureVnet -ResourceGroup $ServicesResourceGroupName
        $ToscaServicesVnet = ($vnet | Select-Object -First 1).name
        Write-Output "Discovered virtual network $($ToscaServicesVnet)"
    }
    catch {
        Write-Error "An Error occurred while attempting to discover the environment vnet: $($_.Exception). Please provide the name of the Tosca environment vnet in the ToscaServicesVnet parameter."
        az logout
        return
    }
} else {
    Write-Output "Using provided vNet $ToscaServicesVnet."
}

try {
    Write-Output "Configuring vnet."
    # Set exception for the local IP on the NSG connected to the client subnet
    # to be able to connect to a packer host later
    $clientSubnet = az network vnet subnet show --resource-group $ServicesResourceGroupName --vnet-name $ToscaServicesVnet --name clients | ConvertFrom-Json
    $nsgRuleName = "tosca_image_creation_$((get-date).Ticks)"
    CreateNsgFirewallException `
        -NsgId $clientSubnet.networkSecurityGroup.id `
        -RuleName $nsgRuleName `
        -port 5986 `
        -Protocol "*" `
        -IpAddress $publicIP
    }
catch {
    Write-Error "An Error occurred while creating a nsg exception: $($_.Exception)"
    az logout
    return
}

if([string]::IsNullOrWhiteSpace($InstallPassword)){
    $InstallPassword = CreateRandomString
}

try {
    Write-Output "Creating Packer image."
    packer.exe build `
        -force `
        -on-error=cleanup `
        -only=azure-arm `
        -var "azure_client_id=$($ServicePrincipalId)" `
        -var "azure_client_secret=$($ServicePrincipalSecret)" `
        -var "azure_subscription_id=$($subscriptionId)" `
        -var "azure_tenant_id=$($tenantId)" `
        -var "azure_region=$($Location)" `
        -var "azure_temp_resource_group_name=$($ClientResourceGroupName)" `
        -var "install_password=$($InstallPassword)" `
        -var "azure_virtual_network_resource_group_name=$ServicesResourceGroupName" `
        -var "azure_virtual_network_name=$ToscaServicesVnet" `
        -var "azure_virtual_network_subnet_name=clients" `
        -var "azure_private_virtual_network_with_public_ip=true" `
        -var "azure_gallery_name=$galleryName" `
        -var "azure_gallery_resource_group=$ServicesResourceGroupName" `
        -var "azure_gallery_target_image_name=$ToscaSetupType" `
        -var "image_version=$ImageVersion" `
        -var "tosca_setup_path=$toscaBlob" `
        -var "toscaserver_setup_path=$toscaServerBlob" `
        -var "toscaserver_patch_path=$serverPatchBlob" `
        -var "tosca_setup_type=$ToscaSetupType" `
        $PackerScriptPath
    
    if($? -eq $false){
        Throw 'An error occurred during the packer build.'
    }
}
catch {
	throw "$($_.Exception)"
    return
} 
finally{
    RemoveNsgFirewallException -NsgId $clientSubnet.networkSecurityGroup.id -RuleName $nsgRuleName
}

try {
    $galleryImageVersion = az sig image-version show `
    --gallery-image-definition $ToscaSetupType `
    --gallery-image-version $ImageVersion `
    --gallery-name $GalleryName `
    --resource-group $ServicesResourceGroupName `
    | ConvertFrom-Json
    
    Write-Output "Successfully built source image:"
    Write-Output "Image gallery resource group: $ServicesResourceGroupName"
    Write-Output "Image gallery name: $galleryName"
    Write-Output "Image publisher: $ImagePublisher"
    Write-Output "Image offer: $ImageOffer"
    Write-Output "Image sku: $ToscaSetupType"
    Write-Output "Image name: $ToscaSetupType"
    Write-Output "Image version: $($galleryImageVersion.name)"
    Write-Output "Image version ID: $($galleryImageVersion.id)"
}
catch {
    Write-Output "An error occurred while evaluating post-creation image details: $($_.Exception)"
}
finally {
    az logout
}
