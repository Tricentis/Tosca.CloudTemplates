<#
.SYNOPSIS
    Post-Deployment configuration script for Tricentis Tosca Server installations.
  
.DESCRIPTION
    This script is intended to be executed after a VM was deployed to configure basic tosca server
    settings. It acts as entry point for other scripts
#>

[CmdletBinding()]
param (
    # Specifies the fully qualified DNS name of a Tosca Server to set as default endpoint for commander.
    [Parameter(Mandatory=$false)]
    [string]$ServerUri,

    # Specifies the fully qualified DNS name of a database instance hosting the tosca repository.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseUri
)

$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "PostDeploy-ToscaServerConfig.ps1"
if(-not (Test-Path -Path $scriptPath)){
    throw "Couldn't find post-deployment script at $scriptPath"
}
pwsh -ExecutionPolicy Unrestricted -File $scriptPath -DatabaseUri $DatabaseUri

$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "PostDeploy-ToscaServerSelfSigned.ps1"
if(-not (Test-Path -Path $scriptPath)){
    throw "Couldn't find post-deployment script at $scriptPath"
}
powershell -ExecutionPolicy Unrestricted -File $scriptPath
