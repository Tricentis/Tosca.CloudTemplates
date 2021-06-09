<#
.Synopsis
   Installs a patch for Tosca server
#>

if([string]::IsNullOrWhiteSpace($env:toscaserver_patch_path)){
   return
}

Set-Location $env:Temp
if(-not(Test-Path .\azcopy.exe)){
   Write-Output "Downloading azcopy"
   Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile ".\azcopy.zip"
   Expand-Archive -Path .\azcopy.zip -DestinationPath ".\azcopy" -Force
   Get-ChildItem -Path .\azcopy -Recurse -Filter azcopy.exe | Move-Item -Destination .
}

Write-Output "Downloading Tosca server patch from $($env:toscaserver_patch_path)"
.\azcopy.exe copy "$($env:toscaserver_patch_path)" .\toscaserverpatch.exe --from-to=BlobLocal --recursive=true

Write-Output "Installing Tosca server patch."
.\toscaserverpatch.exe /s /V"/qn" | Out-Default

Remove-Item -Path .\toscaserverpatch.exe -Force -ErrorAction Ignore