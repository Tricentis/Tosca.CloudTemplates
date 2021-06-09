<#
.Synopsis
   Installs the .net features on windows server
#>

Write-Output "Install .net server feature."
Install-WindowsFeature -Name NET-Framework-Features -IncludeAllSubFeature
Install-WindowsFeature -Name NET-Framework-45-Features -IncludeAllSubFeature
Install-WindowsFeature -Name DSC-Service