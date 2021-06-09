<#
.Synopsis
   VM initialization script
.NOTES
   Customized from https://github.com/actions/virtual-environments/blob/main/images/win/scripts/Installers/
#>

# Enable $ErrorActionPreference='Stop' for AllUsersAllHosts
Add-Content -Path $profile.AllUsersAllHosts -Value '$ErrorActionPreference="Stop"'

# Set TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor "Tls12"

Write-Output "Disable defender real time monitoring"
Set-MpPreference -DisableRealtimeMonitoring $true

Write-Output "Set local execution policy"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine  -ErrorAction Continue | Out-Null

Write-Output "Enable long path behavior"
# See https://docs.microsoft.com/en-us/windows/desktop/fileio/naming-a-file#maximum-path-length-limitation
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

Write-Output "Create folder to host script files"
New-Item -ItemType Directory -Path $env:ProgramData -Name "ToscaPostDeploy" -Force | Out-Null

# Expand disk size of OS drive
Write-Output  "Expand system drive."
$driveLetter = "C"
$size = Get-PartitionSupportedSize -DriveLetter $driveLetter
Resize-Partition -DriveLetter $driveLetter -Size $size.SizeMax