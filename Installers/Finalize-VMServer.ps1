<#
.Synopsis
   Clean up temp folders after installs to save space
.NOTES
   Customized from https://github.com/actions/virtual-environments/blob/main/images/win/scripts/Installers/
#>

Write-Host "Cleaning up image."
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

@(
    "$env:windir\\logs",
    "$env:windir\\Temp",
    "$env:TEMP"
) | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "Removing $_"
        try {
            Takeown /d Y /R /f $_ | Out-Null
            Icacls $_ /GRANT:r administrators:F /T /c /q  2>&1 | Out-Null
            Remove-Item $_ -Recurse -Force | Out-Null
        }
        catch { $global:error.RemoveAt(0) }
    }
}

# Remove AllUsersAllHosts profile
Remove-Item $profile.AllUsersAllHosts -Force -Verbose

# allow msi to write to temp folder
# see https://github.com/actions/virtual-environments/issues/1704
icacls "C:\Windows\Temp" /q /c /t /grant Users:F /T

Write-Output "Enabling Defender real time monitoring."
Set-MpPreference -DisableRealtimeMonitoring $false