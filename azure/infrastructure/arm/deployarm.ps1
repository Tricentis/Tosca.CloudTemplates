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
	
	# Specifies the path to an arm template containing the infrastructure deployment.
    [Parameter(Mandatory=$false)]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "The provided template path $_ does not exist." 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The provided template path $_ must be a file."
        }
        return $true
    })]
	[string]$TemplatePath = "$PSScriptRoot\infrastructure-template.json",

	# Specifies the path to an arm template parameters file for the infrastructure deployment arm template.
	[Parameter(Mandatory=$false)]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "The provided parameters file path $_ does not exist." 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The provided parameters file path $_ must be a file."
        }
        return $true
    })]
    [string]$ParametersPath = "$PSScriptRoot\infrastructure-parameters.json"
)

Write-Output "Getting things ready."
# verify that all files needed for the deployment are available
$functionsPath = "$PSScriptRoot\..\shared\functions.ps1"
if(-not (Test-Path -Path $functionsPath)){
	throw "Could not find $functionsPath"
}

. $functionsPath

$sqlConfigScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "db\ConfigureSQLServer.ps1"
VerifyFile -FilePath $sqlConfigScriptPath

$toscaSQLScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "db\Create Tables AzureSQL.sql"
VerifyFile -FilePath $toscaSQLScriptPath

$deploymentDate = get-date -Format "yyyy-MM-dd-hh-mm"
$deploymentParameters = (Get-Content -Path $ParametersPath -Encoding utf8 | ConvertFrom-Json).parameters

az login --service-principal -u $ServicePrincipalId -p $ServicePrincipalSecret --tenant $deploymentParameters.tenantId.value | ConvertFrom-Json

# Display warning and exit script if az cli is not logged in
$account = az account show | ConvertFrom-Json
if($? -eq $false){
	throw "Could not verify login to azure or az cli is not installed."
}

$sp = az ad sp show --id $ServicePrincipalId | ConvertFrom-Json
Write-Output "Using service principal $($sp.displayName)."

Write-Output "Checking resource groups."
$rgName = $deploymentParameters.servicesResourceGroup.value
try {
	$rg = EnsureResourceGroupExists -Name $rgName
}
catch {
	Write-Output "Could not verify or create resource group $rgName : $($_.Exception)"
	az logout
	return
}

try {
	EnsureDeploymentRoles -Scope $rg.id -UserId $sp.appId
}
catch {
	Write-Output "Could not ensure needed roles for service principal $($sp.appDisplayName): $($_.Exception)"
	az logout
	return
}

$rgClientName = $deploymentParameters.clientResourceGroup.value
try {
	$rgClient = EnsureResourceGroupExists -Name $rgClientName
}
catch {
	Write-Output "Could not verify or create resource group $rgClient : $($_.Exception)"
	az logout
	return
}

try {
	EnsureDeploymentRoles -Scope $rgClient.id -UserId $sp.appId
}
catch {
	Write-Output "Could not ensure needed roles for service principal $($sp.appDisplayName): $($_.Exception)"
	az logout
	return
}

Write-Output "Deploying resources."

$resourceDeployment = az deployment group create `
	--name "toscacloud-infrastructure-$deploymentDate" `
	--resource-group $rgName `
	--template-file $TemplatePath `
	--parameters $ParametersPath

if($? -eq $false){
	az logout
	throw "An error occurred while deploying resources in Azure."
	return
}

Write-Output "Configuring SQL Server."
try {
	. $sqlConfigScriptPath `
		-ResourceGroup $rgName `
		-ServerName $deploymentParameters.sqlServerName.value `
		-ToscaDBName $deploymentParameters.toscaDatabaseName.value `
		-SQLAdminUser $deploymentParameters.sqlAdministratorLogin.value `
		-sqlAdminPassword $deploymentParameters.sqlAdministratorPassword.value `
		-ToscaSQLScriptPath $toscaSQLScriptPath `
	
	$toscaDbConnectionString = az sql db show-connection-string `
		--name $deploymentParameters.toscaDatabaseName.value `
		--server "$($deploymentParameters.sqlServerName.value).database.windows.net" `
		--client ado.net `
		--auth-type sqlpassword
	
		$authDbConnectionString = az sql db show-connection-string `
		--name $deploymentParameters.authDatabaseName.value `
		--server "$($deploymentParameters.sqlServerName.value).database.windows.net" `
		--client ado.net `
		--auth-type sqlpassword
}
catch {
	throw "An Error occurred while configuring the database: $($_.Exception)"
	return
} 
finally {
	RemoveSqlFirewallException -ServerName $deploymentParameters.sqlServerName.value -ResourceGroup $rgName | Out-Null
}

try {
	$saConnectionString =  (az storage account show-connection-string --resource-group $rgName --name $deploymentParameters.storageAccountName.value | ConvertFrom-Json).connectionString
}
finally { 
	az logout
}

Write-Output "The deployment was completed:"
Write-Output "Services resource group name: $rgName"
Write-Output "Clients resource group name: $rgClientName"
Write-Output "Storage account name: $($deploymentParameters.storageAccountName.value)"
Write-Output "Storage account connection string: $saConnectionString"
Write-Output "Azure SQL server: $($deploymentParameters.sqlServerName.value)$($deploymentParameters.$internalDnsFqdn.value)"
Write-Output "Tosca DB name: $($deploymentParameters.toscaDatabaseName.value)"
Write-Output "Tosca DB connection string: $toscaDbConnectionString"
Write-Output "Authentication DB name: $($deploymentParameters.authDatabaseName.value)"
Write-Output "Authentication DB connection string: $authDbConnectionString"
Write-Output "Image gallery name: $($deploymentParameters.imageGalleryName.value)"