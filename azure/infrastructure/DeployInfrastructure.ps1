#requires -modules SqlServer

<#
.SYNOPSIS
    Deploys infrastructure needed to run tosca in azure
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
	[string]$TerraformPath = "$PSScriptRoot",

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

$sqlConfigScriptPath = Join-Path -Path $PSScriptRoot -ChildPath ".\db\ConfigureSQLServer.ps1"
VerifyFile -FilePath $sqlConfigScriptPath

$toscaSQLScriptPath = Join-Path -Path $PSScriptRoot -ChildPath ".\db\Create Tables AzureSQL.sql"
VerifyFile -FilePath $toscaSQLScriptPath

$deploymentParameters = ParseTerraformTfvars -TfvarsPath $TerraformParametersPath

az login --service-principal -u $ServicePrincipalId -p $ServicePrincipalSecret --tenant $deploymentParameters.tenantId | ConvertFrom-Json

# Display warning and exit script if az cli is not logged in
$account = az account show | ConvertFrom-Json
if($? -eq $false){
	throw "Could not verify login to azure or az cli is not installed."
}

$sp = az ad sp show --id $ServicePrincipalId | ConvertFrom-Json
Write-Output "Using service principal $($sp.displayName)."

# Write-Output "Checking resource groups."
# $rgName = $deploymentParameters.servicesResourceGroup
# try {
# 	$rg = EnsureResourceGroupExists -Name $rgName
# }
# catch {
# 	Write-Output "Could not verify or create resource group $rgName : $($_.Exception)"
# 	az logout
# 	return
# }

# try {
# 	EnsureDeploymentRoles -Scope $rg.id -UserId $sp.appId
# }
# catch {
# 	Write-Output "Could not ensure needed roles for service principal $($sp.appDisplayName): $($_.Exception)"
# 	az logout
# 	return
# }

# $rgClientName = $deploymentParameters.clientResourceGroup
# try {
# 	$rgClient = EnsureResourceGroupExists -Name $rgClientName
# }
# catch {
# 	Write-Output "Could not verify or create resource group $rgClient : $($_.Exception)"
# 	az logout
# 	return
# }

# try {
# 	EnsureDeploymentRoles -Scope $rgClient.id -UserId $sp.appId
# }
# catch {
# 	Write-Output "Could not ensure needed roles for service principal $($sp.appDisplayName): $($_.Exception)"
# 	az logout
# 	return
# }

$env:ARM_CLIENT_ID = $ServicePrincipalId
$env:ARM_CLIENT_SECRET = $ServicePrincipalSecret
$env:ARM_SUBSCRIPTION_ID = $deploymentParameters.subscriptionId
$env:ARM_TENANT_ID = $deploymentParameters.tenantId

Set-Location $TerraformPath

terraform init
if($? -eq $false){
	az logout
	throw "An error occurred during terraform init."
}

terraform validate
if($? -eq $false){
	az logout
	throw "An error occurred during terraform validate."
}

Write-Output "Deploying resources."
# Workaround for https://github.com/terraform-providers/terraform-provider-azurerm/issues/828
terraform apply -auto-approve -var-file="$TerraformParametersPath" -var="storage_account_allow_network_access=true" -var="sql_server_allow_network_access=true" 
if($? -eq $false){
	az logout
	throw "An error occurred during terraform apply."
}

$tfOut = (terraform show -json | ConvertFrom-Json).values

Write-Output "Configuring SQL Server."
try {
	. $sqlConfigScriptPath `
		-ResourceGroup ($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "sql_server"}).values.resource_group_name `
		-ServerName ($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "sql_server"}).values.name `
		-ToscaDBName ($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "toscadb"}).values.name `
		-SQLAdminUser ($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "sql_server"}).values.administrator_login `
		-sqlAdminPassword ($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "sql_server"}).values.administrator_login_password `
		-ToscaSQLScriptPath $toscaSQLScriptPath
}
catch {
	throw "An Error occurred while configuring the database: $($_.Exception)"
	return
} 
finally {
	RemoveSqlFirewallException `
        -ServerName ($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "sql_server"}).values.name `
        -ResourceGroup ($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "sql_server"}).values.resource_group_name | Out-Null
    # reapply the terraform template to make sure that the environment is set back to its original state
	terraform apply -auto-approve -var-file="$TerraformParametersPath"
	az logout
}

Write-Output "The deployment was completed:"
terraform output
# Terraform can't directly output the sa connection string since it's marked as sensitive
$tfOut = (terraform show -json | ConvertFrom-Json).values
Write-Output "`"storage_account_connection string = $(($tfOut.root_module.child_modules.resources | Where-Object {$_.name -eq "storage_account"}).values.primary_connection_string)`""
