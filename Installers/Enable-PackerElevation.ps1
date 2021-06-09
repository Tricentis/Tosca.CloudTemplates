<#
.Synopsis
   Enables packer to use elevation.
.NOTES
   Customized from https://github.com/actions/virtual-environments/blob/main/images/win/windows2016.json
#>

Write-Output "Enable elevation for packer."
# net user $env:install_user $env:install_password /add /passwordchg:no /passwordreq:yes /active:yes /Y
# net localgroup Administrators $env:install_user /add

winrm set winrm/config/service/auth '@{Basic="true"}'
winrm get winrm/config/service/auth

# When running scripts with elevation, packer creates a scheduled task and runs it with admin permissions
# This works fine on windows server, but causes issues on windows 10 since the scheduled task is not executed until the executing
# user has logged in to the host
# As workaround autologin can be enabled, see https://groups.google.com/g/packer-tool/c/6ToKPlCpsxM
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1 -type String
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUsername -Value $Env:install_user -type String 
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "$Env:install_password" -type String