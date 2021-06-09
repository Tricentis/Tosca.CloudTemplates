#Requires -PSEdition Core

#########################################
## Post Deploy DEX Agent Configuration ##
#########################################
<#
.SYNOPSIS
    This script will configure Tosca Distribution Agent,
    setting security to Transport for SSL/TLS and updates
    the Tosca Server name from a command line argument
  
.DESCRIPTION
    This script will run during DeployVM.ps1 to set initial 
    configuration and local policies. On first run, the DEX
    Agent will be pointed to the local computername. A second
    run WILL be required once the DNS name of the Tosca Server
    is known

.PARAMETER ServerUri
    The fully qualified DNS name of the Tosca Server that runs 
    the Distribution Service
    
.EXAMPLE
    PS>./PostDeploy-ToscaDEX.ps1 -ServerUri "server.domain.com"
#>

[CmdletBinding()]
Param (
    # Specifies the fully qualified DNS name of a Tosca Server to set as default endpoint for commander.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServerUri,

    # Specifies the fully qualified DNS name of a database instance hosting the tosca repository.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseUri
)

#########################
## Configure DEX Agent ##
######################### 
# Backup DEX Agent Configuration File
$DEXAgent='C:\Program Files (x86)\TRICENTIS\Tosca Testsuite\DistributedExecution\ToscaDistributionAgent.exe.config'
#Test-Path $DEXAgent
Copy-Item -Path "$DEXAgent" -Destination "$DEXAgent.ORIG"

# Configure DEX Agent 
$DEXML = [xml](Get-Content $DEXAgent)
$DEXML.configuration.'system.serviceModel'.bindings.basicHttpBinding.binding.security.SetAttribute("mode","Transport")
$DEXML.configuration.'system.serviceModel'.client.endpoint.SetAttribute("address","https://$ServerUri/DistributionServerService/CommunicationService.svc")
$DEXML.Save($DEXAgent)

###########################
## Configure Environment ##
###########################
# Enable Remote Desktop
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Disable Hibernate
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Power' -name "HibernateEnabled" -value 0

# Disable Screensaver
#Set-ItemProperty -Path ‘HKLM:\Software\Policies\Microsoft\Windows\Control Panel\Desktop\’ -Name "ScreenSaveActive" -Value 0

# Set Time Limit for Disconnected Sessions = DISABLED
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -Name "RemoteAppLogoffTimeLimit" -Value 0

# Always Prompt for Password Upon Connection = DISABLED
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -Name "fPromptForPassword" -Value 0

# Interactive Logon: Do Not Require CTRL+ALT+DEL = ENABLED
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' -Name "DisableCAD" -value 1
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -Name "DisableCAD" -value 1

# Start DEX Agent on Login
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\' -Name 'DEX Agent' -value "C:\Program Files (x86)\TRICENTIS\Tosca Testsuite\DistributedExecution\ToscaDistributionAgent.exe"

###############
## Start DEX ##
###############

# Run ToscaDistributionAgent.exe
."C:\Program Files (x86)\TRICENTIS\Tosca Testsuite\DistributedExecution\ToscaDistributionAgent.exe"