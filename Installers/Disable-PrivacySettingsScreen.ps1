<#
.Synopsis
   Disable the mandatory privacy settings startup screen on windows 10.
#>

Write-Output "Disable Privacy Settings Startup Screen"
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\" -Name "OOBE" -ErrorAction SilentlyContinue
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE\" -Name "DisablePrivacyExperience" -Value 1 -Force   
Write-Output "Choose privacy settings for your device startup screen has been disabled."
