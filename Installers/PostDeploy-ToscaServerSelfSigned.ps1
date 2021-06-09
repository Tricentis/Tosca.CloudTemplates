#Requires -PSEdition Desktop

##########################################
## Tosca Server Self-Signed Certificate ##
##########################################
<#
.SYNOPSIS
   This script runs immediately following DeployVM.ps1. It is meant to 
   create a self-signed TLS certificate based on the COMPUTERNAME, bind 
   the certificate to ToscaServer IIS site, and start the site. 
    
.DESCRIPTION
  This script assumes that the server was built using CreateImage.ps1 and DeployVM.ps1.
  
.EXAMPLE
  Normal Execution -- PS> PostDeploy-ToscaSelfSigned.ps1
 
#>
Import-Module WebAdministration
$ServerName=$env:COMPUTERNAME

# Create Self-Signed Certificate and Bind to ToscaServer Site
$tlscert=(Get-ChildItem Cert:\LocalMachine\My|Where-Object {$_.Subject -match "CN=$ServerName"}|Select-Object -First 1)
if ($null -eq $tlscert){
    $tlscert=New-SelfSignedCertificate -DnsName $ServerName -FriendlyName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
	(Get-WebBinding -Name "ToscaServer" -Protocol "https" -Port 443).AddSslCertificate($tlscert.GetCertHashString(),"my")
 }

# Cycle IIS and ToscaServer
iisreset
Stop-Website -Name ToscaServer
Start-Website -Name ToscaServer