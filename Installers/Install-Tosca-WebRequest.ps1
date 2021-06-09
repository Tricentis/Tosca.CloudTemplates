<#
.Synopsis
   Installs Tricentis Tosca
#>
Write-Output "Installing Tricentis Tosca."
Write-Output "Using setup type $($env:tosca_setup_type)."

Set-Location $env:Temp
Write-Output "Downloading setup from from $(($env:tosca_setup_path).split('?')[0])"
Invoke-WebRequest -Uri "$($env:tosca_setup_path)" -Headers $headers -Method Get -OutFile ".\toscasetup.exe" | Out-Null

switch ($env:tosca_setup_type) {
   { $_ -in "ToscaCommander","ToscaServer" } { 
      Write-Output "Installing Tricentis Tosca with installation type Tosca Commander."
      .\toscasetup.exe /s DIAGNOSTICS=1 ENABLE_TOSCA_BI=1 EXAMPLE_WORKSPACES=1 MOBILE_TESTING=1 OCRDB=1 START_SERVICES=0 NETDRIVE=0 INSTALLDIR="C:\Program Files (x86)\TRICENTIS\Tosca Testsuite" TOSCA_PROJECTS="C:\Tosca_Projects" TRICENTIS_ALLUSERS_APPDATA="C:\ProgramData\TRICENTIS\Tosca Testsuite\7.0.0" /qn | Out-Default
   }
   "DexAgent" { 
      Write-Output "Installing Tricentis Tosca with installation type Dex Agent."
      .\toscasetup.exe /s DIAGNOSTICS=1 ENABLE_TOSCA_BI=0 EXAMPLE_WORKSPACES=0 MOBILE_TESTING=0 OCRDB=0 START_SERVICES=0 NETDRIVE=0 ADDLOCAL=TricentisTBox,DexAgent INSTALLDIR="C:\Program Files (x86)\TRICENTIS\Tosca Testsuite" TOSCA_PROJECTS="C:\Tosca_Projects" TRICENTIS_ALLUSERS_APPDATA="C:\ProgramData\TRICENTIS\Tosca Testsuite\7.0.0" /qn | Out-Default
   }
   Default {
      throw 'Unknown tosca_setup_type $($env:tosca_setup_type) was provided.'
   }
}

Remove-Item -Path .\toscasetup.exe -Force -ErrorAction Ignore -Verbose