<#
.Synopsis
   Installs .net 4.8
#>

Write-Output "Installing .net Framework 4.8"
Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2088631' -OutFile "$env:Temp\Net4.8.exe"
Start-Process -FilePath "$env:Temp\Net4.8.exe" -ArgumentList ("/q","/norestart") -Wait
