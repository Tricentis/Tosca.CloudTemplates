<#
.Synopsis
   Installs the latest version of powershell core.
#>

Write-Output "Installing PowerShell Core."
Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"