<#
.SYNOPSIS
    Deploys virtual machines into a tosca cloud environment
.NOTES
    Requires az cli to run
#>

Param(
    # Specifies the application/client ID of a service principal used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalId,

    # Specifies service principal secret used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
	[string]$ServicePrincipalSecret,

	# Specifies the path to an arm template for the deployed VM.
	[Parameter(Mandatory=$true)]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "The provided template path $_ does not exist." 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The provided template path $_ must be a file."
        }
        return $true
    })]
	[string]$TemplatePath,

	# Specifies the path to an arm template parameters file for the deployed VM.
	[Parameter(Mandatory=$true)]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "The provided parameters file path $_ does not exist." 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The provided parameters file path $_ must be a file."
        }
        return $true
    })]
    [string]$ParametersPath,

    # FQDN of the tosca database.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
	[string]$DatabaseFQDN
)

Write-Output "Getting things ready."
# verify that all files needed for the deployment are available
$functionsPath = "$PSScriptRoot\..\..\shared\functions.ps1"
if(-not (Test-Path -Path $functionsPath)){
	throw "Could not find $functionsPath"
}
. $functionsPath

$deploymentParameters = (Get-Content -Path $ParametersPath -Encoding utf8 | ConvertFrom-Json).parameters
$servicesRg = $deploymentParameters.servicesResourceGroup.value
$clientRg = $deploymentParameters.clientsResourceGroup.value
$imageName = $deploymentParameters.imageName.value
$deploymentDate = get-date -Format "yyyy-MM-dd-hh-mm"

switch ($imageName) {
    { $_ -in "ToscaCommander","DexAgent" } {
        $subnetName = "clients"
        $deploymentRg = $clientRg
        $ToscaServerUri = $deploymentParameters.tocaServerUri.value
    }
    "ToscaServer" {
        $subnetName = "services"
        $deploymentRg = $servicesRg
    }

    Default {
        throw "Unknown image name $imageName."
    }
}

az login --service-principal -u $ServicePrincipalId -p $ServicePrincipalSecret --tenant $deploymentParameters.tenantId.value | Out-Null

# Display warning and exit script if az cli is not logged in
az account show > $null
if($? -eq $false){
    return
}

$sp = az ad sp show --id $ServicePrincipalId | ConvertFrom-Json
Write-Output "Using service principal $($sp.displayName)."

try {
    Write-Output "Getting image details"
    $image = az sig image-definition show `
    --gallery-image-definition $imageName `
    --gallery-name $deploymentParameters.imageGalleryName.value `
    --resource-group $servicesRg `
    | ConvertFrom-Json

    if($? -eq $false){
		throw
    }
}
catch {
    Write-Output "An error occurred while getting image details."
	az logout
	return
}

# The post-deployment script is uploaded to the harddrive of the VM during the image creation process
$deploymentScriptPath = "C:\ProgramData\ToscaPostDeploy"
$ToscaServerUri = $deploymentParameters.tocaServerUri.value

switch ($imageName) {
    "ToscaCommander" {
        $subnetName = "clients"
        $deploymentScriptFile = Join-Path -Path $deploymentScriptPath -ChildPath "PostDeploy-Tosca.ps1"
        $deploymentScriptExecution = "pwsh -ExecutionPolicy Unrestricted -NoProfile -File $deploymentScriptFile -ServerUri '$ToscaServerUri' -DatabaseUri '$DatabaseFQDN'"
    }
    "DexAgent" {
        $subnetName = "clients"
        $deploymentScriptFile = Join-Path -Path $deploymentScriptPath -ChildPath "PostDeploy-ToscaDEX.ps1"
        $deploymentScriptExecution = "pwsh -ExecutionPolicy Unrestricted -NoProfile -File $deploymentScriptFile -ServerUri '$ToscaServerUri' -DatabaseUri '$DatabaseFQDN'"
    }
    "ToscaServer" {
        $subnetName = "services"
        $deploymentScriptFile = Join-Path -Path $deploymentScriptPath -ChildPath "PostDeploy-ToscaServerAzure.ps1"
        $deploymentScriptExecution = "pwsh -ExecutionPolicy Unrestricted -NoProfile -File $deploymentScriptFile -ServerUri '' -DatabaseUri '$DatabaseFQDN'"
    }

    Default {
        az logout
        throw "Unknown image name $imageName."
    }
}

Write-Output "Deploying resources."
az deployment group create `
	--name "$($deploymentParameters.imageName.value)-$deploymentDate" `
    --resource-group $deploymentRg `
    --template-file $TemplatePath `
    --parameters $ParametersPath `
	--parameters deploymentScriptExecution=$deploymentScriptExecution SubnetName=$subnetName`

if($? -eq $false){
	Write-Output "An error occurred while deploying resources in Azure."
	az logout
	return
}

$vmIP = az vm list-ip-addresses --name $deploymentParameters.vmName.value  --resource-group $deploymentRg | ConvertFrom-Json
$pubIP = az network public-ip show --ids $vmIP.virtualMachine.network.publicIpAddresses.id | ConvertFrom-Json

Write-Output "Deployed new VM."
Write-Output "Resource group: $($pubIP.resourceGroup)"
$env:DEPL_RESOURCEGROUP = $pubIP.resourceGroup
Write-Output "Resource name: $($deploymentParameters.vmName.value)"
$env:DEPL_RESOURCENAME = $deploymentParameters.vmName.value
Write-Output "Public IP address: $($pubIP.ipAddress)"
$env:DEPL_PUBLICIP = $pubIP.ipAddress
Write-Output "Public FQDN: $($pubIP.dnsSettings.fqdn)"
$env:DEPL_PUBLICFQDN = $pubIP.dnsSettings.fqdn
Write-Output "Private IP address: $($vmip.virtualMachine.network.privateIpAddresses)"
$env:DEPL_PRIVATEIP = $vmip.virtualMachine.network.privateIpAddresses
Write-Output "Private hostname: $($deploymentParameters.vmName.value)"
$env:DEPL_HOSTNAME = $deploymentParameters.vmName.value

az logout