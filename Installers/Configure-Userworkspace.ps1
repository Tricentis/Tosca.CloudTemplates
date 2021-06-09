<#
.Synopsis
   Configures a user workspace on windows server 2016
.NOTES
   See https://support.tricentis.com/community/manuals_detail.do?lang=en&version=14.0.0&url=installation_tosca/windows2016_overview.htm
#>

# debug 
Get-ChildItem "C:\Users\bobadmin\Desktop\Tricentis\Tosca TestSuite\7.0.0\Settings" | Remove-Item -Force
# debug


Write-Output "Creating user-specific workspace configuration."
Write-Output "Coping setting files."

$targetDir = Join-Path -Path $env:USERPROFILE -ChildPath "Desktop\Tricentis\Tosca TestSuite\7.0.0\Settings"
New-Item -Path $targetDir -ItemType Directory -Force | Out-Null

$sourceDir = Join-Path -Path $env:TRICENTIS_HOME -ChildPath "dll\Settings\XML"
Set-Location -Path $sourceDir

Copy-Item -Path (Join-Path -Path $sourceDir -ChildPath "License.xml") -Destination $targetDir -Verbose -Force
Copy-Item -Path (Join-Path -Path $sourceDir -ChildPath "MetaSettings.xml") -Destination $targetDir -Verbose -Force

# Update MetaSettings.xml to point to the new license.xml file
$licenseXml = (Get-ChildItem -Path $targetDir -Filter "License.xml").FullName.replace($env:USERPROFILE, "`${APPDATA}")
$metaSettingsXml = Get-ChildItem -Path $targetDir -Filter "MetaSettings.xml"
$settingsContent = Get-Content -Path $metaSettingsXml 
$settings = [xml]$settingsContent
$ns = $settings.DocumentElement.NamespaceURI

$settings.TOSCAMetaSettings.Sources.XmlFile | Where-Object {$_ -match "License.xml"} = "AA"

