<#
.Synopsis
   Update the .net security protocol to TLS 1.2
.NOTES
   Customized from https://github.com/actions/virtual-environments/blob/main/images/win/scripts/Installers/
#>

Write-Output "Updating TLS settings."
Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework"

$registryPath = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
$name = "SchUseStrongCrypto"
$value = "1"
if(Test-Path $registryPath){
    Set-ItemProperty -Path $registryPath -Name $name -Value $value -Type DWORD
}

$registryPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"
if(Test-Path $registryPath){
    Set-ItemProperty -Path $registryPath -Name $name -Value $value -Type DWORD
}

Set-Location $env:Temp
Invoke-WebRequest -Uri "https://www.nartac.com/Downloads/IISCrypto/IISCryptoCli.exe" -OutFile ".\IISCryptoCli.exe"
.\IISCryptoCli.exe /template best