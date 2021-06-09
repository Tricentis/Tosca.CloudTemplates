<#
.Synopsis
   Configures Firewall rules needed to integrate with tosca products
.NOTES
   See https://documentation.tricentis.com/tosca/1400/en/content/tosca_server/server_ports.htm
#>

Write-Host "Setting Firewall for Tosca Server Components"
New-NetFirewallRule -DisplayName "ToscaAdministrationConsole" -Description "Tosca Administration Console" -Direction Inbound -LocalPort 5010 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "ToscaAdministrationConsole" -Description "Tosca Administration Console" -Direction Outbound -LocalPort 5010 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisMigrationService" -Description "Tricentis Migration Service" -Direction Inbound -LocalPort 5011 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisAutomationObjectService" -Description "Tricentis Automation Object Service" -Direction Outbound -LocalPort 5006 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisAutomationObjectService" -Description "Tricentis Automation Object Service" -Direction Inbound -LocalPort 5006 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisToscaServerLandingPage" -Description "Tricentis Tosca Server Landing Page" -Direction Inbound -LocalPort 5012 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisTestDataService" -Description "Tricentis Test Data Service" -Direction Inbound -LocalPort 5001 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisFileService" -Description "Tricentis File Service" -Direction Inbound -LocalPort 5005 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisServiceDiscovery" -Description "Tricentis Service Discovery" -Direction Inbound -LocalPort 5002 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisProjectService" -Description "Tricentis Project Service" -Direction Inbound -LocalPort 5003 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisAuthenticationService" -Description "Tricentis Authentication Service" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
