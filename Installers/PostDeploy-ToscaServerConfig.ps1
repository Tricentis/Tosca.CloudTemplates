#Requires -PSEdition Core

############################################
## Post Deploy Tosca Server Configuration ##
############################################
<#
.SYNOPSIS
    This script runs immediately following PostDeploy-ToscaServerSelfSigned.ps1
    and is automatically called during the DeployVM.ps1 script. This script 
    will set up initial configuration needed for Tosca Server to start. This
    script does the following:
      
    - Update Service Discovery with the server COMPUTERNAME
    - Update File Service storage path
    - Update DEX AOS URL
    - Add DEX AOS Workspace and Admin User
    - Enable AOS 
    - Update Landing Page URLs
    - Restart Tricentis Services and IIS 

.DESCRIPTION
    This script assumes that PostDeploy-ToscaServerSelfSigned.ps1 has executed, and there is 
    a TLS certificate imported and bound to ToscaServer IIS site. As this is an initial
    configuration, these values are meant to be default and are subject to change.
    
 .EXAMPLE
  Normal Execution -- PS> PostDeploy-ToscaServerConfig.ps1 
  
#>

#######################
## Define Parameters ##
#######################
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    $ServerName = $env:COMPUTERNAME,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $DatabaseUri,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String[]]
    $Thumbprint,
    
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    $DEXWorkspace = "DEX"
    
)
####################
## End Parameters ##
####################

######################
## Define Functions ##
######################
function Format-Json([Parameter(Mandatory, ValueFromPipeline)][String] $json) {
    $indent = 0;
    ($json -Split '\n' |
      ForEach-Object {
        if ($_ -match '[\}\]]') {
          # This line contains  ] or }, decrement the indentation level
          $indent--
        }
        $line = (' ' * $indent * 2) + $_.TrimStart().Replace(':  ', ': ')
        if ($_ -match '[\{\[]') {
          # This line contains [ or {, increment the indentation level
          $indent++
        }
        $line
    }) -Join "`n"
  }
###################
## End Functions ##
###################

##################
## Housekeeping ##
##################
# Get Certificate Thumbprint
if (!$Thumbprint){
    $Thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -match "CN=$ServerName"}).Thumbprint;
}
####################
# End Housekeeping #
####################
# Update ServiceDiscovery Hostname
$Disco="C:\Program Files (x86)\TRICENTIS\Tosca Server\ServiceDiscovery\appsettings.json"
Copy-Item -Path "$Disco" -Destination "$Disco.$(get-date -f yyyyMMdd).ORIG"
$EditDisco=Get-Content $Disco|ConvertFrom-Json
$EditDisco.Discovery.ServiceDiscovery="http://$ServerName`:5002"
ConvertTo-Json -Depth 99 $EditDisco|Format-Json|Out-File $Disco 

# Update File Service Storage Directory Path
New-Item -Path "C:\" -Name "Tosca_Storage" -ItemType "directory" -Force
$FsLoc=Get-Content "C:\Program Files (x86)\TRICENTIS\Tosca Server\FileService\appsettings.json"|ConvertFrom-Json
$FsLoc.RootDirectoryPath = "C:\Tosca_Storage"
ConvertTo-Json -Depth 99 $FsLoc|Format-Json|Out-File "C:\Program Files (x86)\TRICENTIS\Tosca Server\FileService\appsettings.json"

# Update AOS - DEX URL
$AOS=Get-Content "C:\Program Files (x86)\TRICENTIS\Tosca Server\AutomationObjectService\appsettings.json"|ConvertFrom-Json
$AOS.AutomationObjectServiceConfig.DexBaseUrl="https://$ServerName"
ConvertTo-Json -Depth 99 $AOS|Format-Json|Out-File "C:\Program Files (x86)\TRICENTIS\Tosca Server\AutomationObjectService\appsettings.json" 

# Add AOS Workspace Config 
$AOS2=Get-Content "C:\Program Files (x86)\TRICENTIS\Tosca Server\AutomationObjectService\appsettings.json"|ConvertFrom-Json
$AOS2.AutomationObjectServiceConfig.Workspaces=@()
$AOSWorkspace=[PSCustomObject]@{
  CommonRepositoryConnectionString=''
  ProjectId= $DEXWorkspace
  WorkspacePassword='21489a0b-c163-4a62-b61e-501090c9506aMgAxADQAOAA5AGEAMABiAC0AYwAxADYAMwAtADQAYQA2ADIALQBiADYAMQBlAC0ANQAwADEAMAA5ADAAYwA5ADUAMAA2AGEAMtYWj41lUSzW/bNwsgkeLw=='
  WorkspaceUserName='Admin'
}
$AOS2.AutomationObjectServiceConfig.Workspaces += $AOSWorkspace
ConvertTo-Json -Depth 99 $AOS2 |Format-Json|Out-File "C:\Program Files (x86)\TRICENTIS\Tosca Server\AutomationObjectService\appsettings.json"

# Update DEX Server Web.config - Set FQDN and Enable AOS
$DEX='C:\Program Files (x86)\TRICENTIS\Tosca Server\DEXServer\Web.config'
Test-Path $DEX
Copy-Item -Path "$DEX" -Destination "$DEX.ORIG"

# Add DEX Workspace Configuration for AOS
$DEXML = [xml](Get-Content $dex)
$d=$DEXML.SelectSingleNode("/configuration/applicationSettings/Tricentis.DistributionServer.Properties.Settings/setting[@name='EnableWorkspacelessExecution']")
$d.value ="True"
$DEXML.Save($DEX)
(Get-Content $DEX) -replace "http://localhost", "https://$ServerName"  | Set-Content $DEX

# Update Landing Page URLs
$LandingURL="C:\Program Files (x86)\TRICENTIS\Tosca Server\LandingPage\wwwroot\resources\data\data.xml"
(Get-Content $LandingURL -raw) -replace "localhost",$ServerName|Out-File $LandingURL

####################
# Services Restart #
####################
# Cycle Tricentis Services
Get-Service -Name Tricentis* | Stop-Service -Force
Get-Service -Name Tosca* | Stop-Service -Force
Start-Sleep -Seconds 5
Start-Service -Name Tricentis.LandingPage
Start-Service -Name Tricentis.ServiceDiscovery
Start-Service -Name Tricentis.AuthenticationService 
Start-Service -Name Tricentis.ProjectService
Start-Service -Name Tricentis.FileService
Start-Service -Name Tricentis.MigrationService
Start-Service -Name ToscaAdministrationConsole
Start-Service -Name Tricentis.ToscaAutomationObjectService
Start-Service -Name Tricentis.TestDataService
Start-Sleep -Seconds 5

# Cycle IIS and ToscaServer
iisreset