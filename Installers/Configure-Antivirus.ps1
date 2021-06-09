<#
.Synopsis
   Configures Antivirus
.NOTES
   Customized from https://github.com/actions/virtual-environments/blob/main/images/win/scripts/Installers/
#>

Write-Host "Set antivirus parameters"
Set-MpPreference -ScanAvgCPULoadFactor 5 -ExclusionPath "D:\", "C:\"