<#
.Synopsis
   Disable Internet Explorer welcome screen on windows 10.
#>

Write-Output "Disable Internet Explorer welcome screen"
$AdminKey = "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main"
New-Item -Path $AdminKey -Value 1 -Force
Set-ItemProperty -Path $AdminKey -Name "DisableFirstRunCustomize" -Value 1 -Force