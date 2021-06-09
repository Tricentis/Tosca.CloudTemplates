<#
.SYNOPSIS
    Post-Deployment configuration script for Tricentis Tosca Commander installations.
  
.DESCRIPTION
    This script is intended to be executed after a VM was deployed to configure several settings
    to integrate it to a tosca cloud environment.

.EXAMPLE
    PS> .\PostDeploy-Tosca.ps1 -ServerUri "server.domain.com"
#>

[CmdletBinding()]
param (
    # Specifies the fully qualified DNS name of a Tosca Server to set as default endpoint for commander.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServerUri,

    # Specifies the fully qualified DNS name of a database instance hosting the tosca repository.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseUri,

    # Specifies the path to the tosca settings url to update.
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$SettingsPath = "C:\ProgramData\TRICENTIS\Tosca Testsuite\7.0.0\Settings\XML\Settings.xml"
)

function CreateServerEndpoint(){
    Param
    (
        [Parameter(Mandatory=$true)]
        [System.Xml.XmlNode]$Document,
        [Parameter(Mandatory=$true)]
        [string]$ServerUri,
        [Parameter(Mandatory=$true)]
        [string]$NameSpace,
        [Parameter(Mandatory=$true)]
        [string]$LegacyPath,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$SettingName

    )

    $el = $Document.CreateNode("element","Category", $NameSpace)
    $el.SetAttribute("name",$Name)

    $setting = $Document.CreateNode("element","Setting", $NameSpace)
    $setting.SetAttribute("name",$SettingName)
    $setting.SetAttribute("legacyPath",$LegacyPath)
    $setting.InnerText = $ServerUri

    [void]$el.AppendChild($setting)
    return $el
}

Write-Output "Post deployment script Tricentis Tosca"
Write-Output "Setting tosca server endpoint in `"$SettingsPath`" to $serverUri."

$settingsContent = Get-Content -Path $settingsPath 
$settings = [xml]$settingsContent
$ns = $settings.DocumentElement.NamespaceURI

$commander = $settings.TOSCASettings.ChildNodes | Where-Object {$_.name -eq "Commander"}
if($null -eq $commander){
    $commander = $settings.CreateNode("element","Category", $ns)
    $commander.SetAttribute("name","Commander")
    [void]$settings.TOSCASettings.AppendChild($commander)
}

$dex = $commander.ChildNodes | Where-Object {$_.name -eq "DistributedExecution"}
if($null -eq $dex){
    $dex = $settings.CreateNode("element","Category", $ns)
    $dex.SetAttribute("name","DistributedExecution")
    [void]$commander.AppendChild($dex)
}

$nodes = @(
    [PSCustomObject]@{Uri="https://$serverUri/DistributionServerService/ManagerService.svc"; SettingName="EndpointAddress"; LegacyPath="Commander.DistributedExecution.Server.EndpointAddress"; Name="Server"; Path=$dex },
    [PSCustomObject]@{Uri="https://$serverUri/monitor"; SettingName="Url"; LegacyPath="Commander.DistributedExecution.MonitorUrl.Url"; Name="Monitor Url"; Path=$dex },
    [PSCustomObject]@{Uri="https://$serverUri/explore"; SettingName="ServerEndpointAddress"; LegacyPath="Commander.ExploratoryTesting.ServerEndpointAddress"; Name="ExploratoryTesting"; Path=$commander }
    [PSCustomObject]@{Uri="https://$serverUri/interactive"; SettingName="ServerEndpointAddress"; LegacyPath="Commander.InteractiveTesting.ServerEndpointAddress"; Name="InteractiveTesting"; Path=$commander }
    [PSCustomObject]@{Uri="https://$ServerUri`:5002"; SettingName="ServerEndpointAddress"; LegacyPath="TricentisServices.ServerEndpointAddress"; Name="Tricentis Services"; Path=$settings.TOSCASettings }
)

foreach ($node in $nodes)
{
    $newElement = CreateServerEndpoint `
        -Document $settings `
        -ServerUri $node.Uri `
        -NameSpace $ns `
        -LegacyPath $node.LegacyPath `
        -Name $node.Name `
        -SettingName $node.SettingName

    $element = $node.Path.ChildNodes | Where-Object {$_.name -eq $node.Name}
    if($null -eq $element -or $element.GetElementsByTagName('Setting').count -eq 0){
        Write-Output "Creating node $($node.Name) with endpoint $($node.LegacyPath), for server address $($node.Uri)"
        [void]$node.Path.AppendChild($newElement)
    } else {
        $endpoint = $element.Setting | Where-Object {$_.name -eq $node.SettingName -and $_.legacyPath -eq $node.LegacyPath }
        if($null -eq $endpoint){
            Write-Output "Creating node $($node.Name) with endpoint $($node.LegacyPath), for server address $($node.Uri)"
            [void]$node.Path.AppendChild($newElement)
        } else {
            Write-Output "Found node $($node.Name) with endpoint $($node.LegacyPath), setting server address to $($node.Uri)"
            $endpoint.InnerText = $node.Uri
        }
    }
}

$settings.Save("$settingsPath")
Get-Content -Path $settingsPath