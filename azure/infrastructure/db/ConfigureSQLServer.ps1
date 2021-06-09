#requires -modules SqlServer

<#
.SYNOPSIS
    Configures an Azure SQL server for Tosca
.DESCRIPTION
    The script connects to an Azure SQL database and runs a SQL script
    to create tables, objects, etc. after which the database is ready to use
    for Tosca, Server, etc.
    Also see https://support.tricentis.com/community/manuals_detail.do?lang=en&version=14.0.0&url=installation_tosca/prepare_multiuser.htm for
    the respective tosca version.

    Snapshot isolation does not need to be set since it's already activated by default for Azure SQL databases.
.NOTES
    Requires az cli to run
#>

[CmdletBinding()]
Param
(
    # Specifies the SQL Server Name used by Tosca
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,

    # Specifies the name of the resource group containinig the SQL server
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroup,

    # Specifies the database name used by Tosca
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ToscaDBName,

    # Specifies the SQL server admin name
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$SQLAdminUser,

    # Specifies the SQL server admin password
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$sqlAdminPassword, 

    # Specifies the path to a sql configuration script for tosca
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if( -Not ($_ | Test-Path) ){
            throw "Could not find SQL Configuration script at $_"
        }
        return $true
    })]
    [string]$ToscaSQLScriptPath = "$PSScriptRoot\Create Tables AzureSQL.sql"
)

. $PSScriptRoot\..\..\..\shared\functions.ps1

# Display warning and exit script if az cli doesn't have a login session
az account show > $null
if($? -eq $false){
    return
}

Write-Output "Getting public IP."
try {
	$publicIP = GetExternalIPAddress
}
catch {
    throw "An Error occurred while evaluating the public IP address of this host: $($_.Exception)"
}

try {
    CreateSqlFirewallException -ServerName $Servername -ResourceGroup $ResourceGroup -IPAddress $publicIP

    WaitForSQLFirewallException `
        -ResourceGroup $ResourceGroup `
        -ServerName $Servername `
        -DBName $ToscaDBName `
        -SQLAdminUser $SQLAdminUser `
        -sqlAdminPassword $sqlAdminPassword 
}
catch {
    Write-Output "An error occurred while setting the database connection: $($_.Exception)"
    RemoveSqlFirewallException -ServerName $servername -ResourceGroup $ResourceGroup
    throw
}

# See https://support.tricentis.com/community/manuals_detail.do?lang=en&version=13.4.0&url=installation_tosca/prepare_multiuser.htm
$fqdn = "$Servername.database.windows.net"
$pass = ConvertTo-SecureString $sqlAdminPassword -AsPlainText -Force
$loginCred = New-Object System.Management.Automation.PSCredential($SQLAdminUser, $pass)

try {
    Write-Output "Creating Tables"
    Invoke-Sqlcmd -ServerInstance $fqdn -Database $ToscaDBName -InputFile $ToscaSQLScriptPath -Credential $loginCred
}
catch {
    throw  "An error occurred while preparing the database: $($_.Exception)"
}
finally {
    RemoveSqlFirewallException -ServerName $Servername -ResourceGroup $ResourceGroup
}

