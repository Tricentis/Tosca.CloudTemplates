<#
.Synopsis
   Installs the AWS RDS root certifacte
#>

Write-Output "Installing the AWS RDS root certificate."
$awsRootCertUrl = 'https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem'
$downloadLocation = Join-Path -Path $env:Temp -ChildPath "rds-root.pem"

Set-Location $env:Temp
Write-Output "Downloading the certificate from $awsRootCertUrl."
Invoke-WebRequest -Uri $awsRootCertUrl -OutFile $downloadLocation

Import-Certificate -FilePath $downloadLocation -CertStoreLocation Cert:\LocalMachine\Root

Remove-Item -Path $downloadLocation -Force -ErrorAction Ignore -Verbose