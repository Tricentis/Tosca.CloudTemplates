<#
.Synopsis
   Configures Firewall rules needed to integrate with tosca products
.NOTES
   See https://documentation.tricentis.com/tosca/1400/en/content/installation_tosca/ports.htm
#>
 
Write-Host "Setting Firewall for Tosca Components"
New-NetFirewallRule -DisplayName "TricentisLicenseServer" -Description "Tricentis License Server" -Direction Inbound -LocalPort 7070 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisLicenseServer" -Description "Tricentis License Server" -Direction Outbound -LocalPort 7070 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisMSSQLConnection" -Description "Tricentis MS SQL Connection" -Direction Outbound -LocalPort 1433 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisMobileEngineAppium" -Description "Tricentis Mobile EngineAppium" -Direction Outbound -LocalPort 4723 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisActiveDirectoryIntegration" -Description "Tricentis Active Directory Integration" -Direction Outbound -LocalPort 389 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisActiveDirectoryIntegration" -Description "Tricentis Active Directory Integration" -Direction Outbound -LocalPort 389 -Protocol UDP -Action Allow
New-NetFirewallRule -DisplayName "TricentisContinuousIntegration" -Description "Tricentis Continuous Integration" -Direction Inbound -LocalPort 8732 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisSAPIntegrationSolman" -Description "Tricentis SAP Integration Solman" -Direction Outbound -LocalPort 8000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisSAPIntegrationSolmanSLD" -Description "Tricentis SAP Integration Solman SLD" -Direction Outbound -LocalPort 50000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisCommunicationClientServer" -Description "Tricentis Communication ClientServer" -Direction Inbound -LocalPort 50000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "TricentisCommunicationClientServer" -Description "Tricentis  Communication ClientServer" -Direction Outbound -LocalPort 50000 -Protocol TCP -Action Allow