<#
.SYNOPSIS
    Deploys virtual machines into a tosca cloud environment
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
	
	# Specifies the path to a folder containing terraform template files used to deploy the resources.
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
	[string]$TerraformPath,

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
    [string]$TerraformParametersPath
)


Write-Output "Getting things ready."
# verify that all files needed for the deployment are available
$functionsPath = "$PSScriptRoot\..\..\shared\functions.ps1"
if(-not (Test-Path -Path $functionsPath)){
	throw "Could not find $functionsPath"
}
. $functionsPath

$deploymentParameters = ParseTerraformTfvars -TfvarsPath $TerraformParametersPath

$env:ARM_CLIENT_ID = $ServicePrincipalId
$env:ARM_CLIENT_SECRET = $ServicePrincipalSecret
$env:ARM_SUBSCRIPTION_ID = $deploymentParameters.subscriptionId
$env:ARM_TENANT_ID = $deploymentParameters.tenantId

# The post-deployment script is uploaded to the harddrive of the VM during the image creation process
$deploymentScriptPath = "C:\ProgramData\ToscaPostDeploy"

switch ($deploymentParameters.installation_type) {
    "ToscaCommander" {
        $deploymentScriptFile = (Join-Path -Path $deploymentScriptPath -ChildPath "PostDeploy-Tosca.ps1") -replace '\\','/'
    }
    "DexAgent" {
        $deploymentScriptFile = (Join-Path -Path $deploymentScriptPath -ChildPath "PostDeploy-ToscaDEX.ps1") -replace '\\','/'
    }
    "ToscaServer" {
        $deploymentScriptFile = (Join-Path -Path $deploymentScriptPath -ChildPath "PostDeploy-ToscaServerAzure.ps1") -replace '\\','/'
    }

    Default {
        throw "Unknown installation_type $($deploymentParameters.installation_type)."
    }
}

Write-Output "Deploying resources."
Set-Location $TerraformPath

terraform init
if($? -eq $false){
	Write-Output "An error occurred during terraform init."
	return
}

terraform validate
if($? -eq $false){
	Write-Output "An error occurred during terraform validate."
	return
}

terraform apply -auto-approve `
    -var-file="$TerraformParametersPath" `
    -var postdeploy_script_path="$deploymentScriptFile"

if($? -eq $false){
	Write-Output "An error occurred during terraform apply."
	return
}

$tfOut = (terraform show -json | ConvertFrom-Json).values

Write-Output "The deployment was completed:"
terraform output