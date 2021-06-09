<#
.SYNOPSIS
    Uploads tosca setups to an azure storage account
.NOTES
    Requires az cli to run
#>

Param(
	# Specifies the path to a folder containing terraform template files used to deploy the infrastructure.
    [Parameter(Mandatory=$false)]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "The provided terraform path $_ does not exist." 
        }
        if(-Not ($_ | Test-Path -PathType Container) ){
            throw "The provided terraform path $_ must be a directory."
        }
        return $true
    })]
	[string]$TerraformPath = "$PSScriptRoot\..\infrastructure",

	# Specifies the path to an terraform variables file for the deployment template.
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
    [string]$TerraformParametersPath,
    
    # Specifies service principal ID used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalId,

    # Specifies service principal secret used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalSecret,

    # If set to true, all uploaded setups are removed from the storage account.
    [Parameter(Mandatory=$true,  ParameterSetName = 'clean')]
    [ValidateNotNullOrEmpty()]
    [switch]$ClearStorageAccount,

    # Specifies the path to an installation executable for Tricentis Tosca.
    [Parameter(Mandatory=$false, ParameterSetName = 'upload')]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "The provided tosca installation executable path $_ does not exist." 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The provided tosca installation executable path $_ must be a file."
        }
        return $true
    })]
    [string]$ToscaSetupPath,

    # Specifies the path to an installation executable for Tosca Server.
    [Parameter(Mandatory=$false, ParameterSetName = 'upload')]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "The provided tosca server installation executable path $_ does not exist." 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The provided tosca server installation executable path $_ must be a file."
        }
        return $true
    })]
    [string]$ToscaServerSetupPath,

    # Specifies the path to an patch executable for Tosca Server.
    [Parameter(Mandatory=$false, ParameterSetName = 'upload')]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "The provided tosca server patch executable path $_ does not exist." 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The provided tosca server patch executable path $_ must be a file."
        }
        return $true
    })]
    [string]$ToscaServerPatchPath
)

Write-Output "Tosca setup uploader."

if($PSCmdlet.ParameterSetName -eq 'upload' `
    -and [string]::IsNullOrWhiteSpace($ToscaSetupPath) `
    -and [string]::IsNullOrWhiteSpace($ToscaServerSetupPath) `
    -and [string]::IsNullOrWhiteSpace($ToscaServerPatchPath)
    ){
    Write-Warning "Not setups were provided, aborting script."
    return
}

Write-Output "Getting things ready."
$functionsPath = "$PSScriptRoot\..\..\shared\functions.ps1"
if(-not (Test-Path -Path $functionsPath)){
	throw "Could not find $functionsPath"
}
. $functionsPath

$deploymentParameters = ParseTerraformTfvars -TfvarsPath $TerraformParametersPath
$saName = $deploymentParameters.storage_account_name
$servicesResourceGroupName = $deploymentParameters.resource_group_services_name
$tenantId = $deploymentParameters.tenantId

$env:ARM_CLIENT_ID = $ServicePrincipalId
$env:ARM_CLIENT_SECRET = $ServicePrincipalSecret
$env:ARM_SUBSCRIPTION_ID = $deploymentParameters.subscriptionId
$env:ARM_TENANT_ID = $tenantId

az login --service-principal -u $ServicePrincipalId -p $ServicePrincipalSecret --tenant $TenantId | ConvertFrom-Json

# Display warning and exit script if az cli is not logged in or not able to connect to subscription
az account show > $null
if($? -eq $false){
    return
}

Write-Output "Configuring storage account."
try {
    CreateSaFirewallException -SaName $saName -ResourceGroup $ServicesResourceGroupName
    Start-Sleep -Seconds 60
}
catch {
    Write-Error "An Error occurred while configuring the storage account: $($_.Exception)"
    az logout
    throw
    return
}

Set-Location -Path $TerraformPath
$tfOut = (terraform show -json | ConvertFrom-Json).values
$saConnectionString = ($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "storage_account"}).values.primary_connection_string
$blobEndpoint = ($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "storage_account"}).values.primary_blob_endpoint

if($PSCmdlet.ParameterSetName -eq 'clean'){
    Write-Output "The ClearStorageAccount parameter was provided, removing all files in the setup container on the storage account."

    try {
        az storage blob delete-batch --connection-string $saConnectionString --source setup --dryrun
        az storage blob delete-batch --connection-string $saConnectionString --source setup
    }
    catch {
        throw "An Error occurred while removing setups : $($_.Exception)"
    } 
    finally {
        terraform apply -auto-approve -var-file="$TerraformParametersPath"
        az logout
    }

    return
}

$setups = @(
    [PSCustomObject]@{
        FriendlyName = "Tosca server patch"
        Path = $ToscaServerPatchPath
        BlobPath = $null
    },
    [PSCustomObject]@{
        FriendlyName = "Tosca server setup"
        Path = $ToscaServerSetupPath
        BlobPath = $null
    },
    [PSCustomObject]@{
        FriendlyName = "Tricentis Tosca setup"
        Path = $ToscaSetupPath
        BlobPath = $null
    }
)

try {
    foreach ($setup in $setups) {
        if([string]::IsNullOrWhiteSpace($setup.Path)){
            continue
        }
    
        Write-Output "Starting upload for $($setup.FriendlyName) from $($setup.Path) to storage account $($saName)."
        $localFileName = Split-Path $setup.Path -Leaf
        az storage blob upload --connection-string $saConnectionString --container-name setup --file "$($setup.Path)" --name $localFileName --validate-content
        
        if($? -eq $false){
            throw
        }

        $setup.BlobPath = "$blobEndpoint/setup/$localFileName"
        Write-Output "Uploaded $($setup.FriendlyName)."
    }

    Write-Output "Successfully uploaded setups:"
    foreach ($setup in $setups) {
        if($null -eq $setup.BlobPath){
            continue
        }
        Write-Output "$($setup.FriendlyName): $($setup.BlobPath)"
    }
}
catch {
    throw "An Error occurred while uploading the setup: $($_.Exception)"
}
finally {
    terraform apply -auto-approve -var-file="$TerraformParametersPath"
    az logout
}