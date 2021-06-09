<#
.Synopsis
   Runs sysprep for azure images
#>

Write-Output "Generalizing image."
while ((Get-Service RdAgent).Status -ne 'Running') {
    Write-Output 'Waiting for RDAgent service to start.'
    Start-Sleep -s 5
}

while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') {
    Write-Output 'Waiting for WindowsAzureGuestAgent service to start.'
    Start-Sleep -s 5
}

Write-Host 'Running sysprep.'
if(Test-Path $Env:SystemRoot\\System32\\Sysprep\\unattend.xml){
    Remove-Item $Env:SystemRoot\\System32\\Sysprep\\unattend.xml -Force
}

& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit
while ($true) {
    $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState
    if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { 
        Write-Output $imageState.ImageState
        Start-Sleep -s 60  
    } else { 
        break 
    }
}
