<#
.Synopsis
   Installs the Azure Pipelines agent
#>

[CmdletBinding()]
Param
(
    # PAT that will be use to authorize the agent
    [Parameter(Mandatory=$true)]
    [string]$PAT,

    # URL of the Azure DevOps organization
    [Parameter(Mandatory=$true)]
    [string]$Tenant,

    # Name of the agent pool
    [Parameter(Mandatory=$true)]
    [string]$AgentPool,

    # Name of the agent
    [Parameter(Mandatory=$true)]
    [string]$AgentName,

    # Username of a local account to run the agent
    [Parameter(Mandatory=$true)]
    [string]$VMAdminUser,

    # Password of a local account to run the agent
    [Parameter(Mandatory=$true)]
    [string]$VMAdminPassword,

    # Directory to install the agent into
    [Parameter(Mandatory=$false)]
    [string]$AgentDirectory = 'C:\a'
)

function Get-AgentInstaller
{
    [CmdletBinding()]
    param(
        [string] $Tenant,
        [string] $PAT
    )

    # Create a temporary to download the installer
    $agentTempFolderName = Join-Path $env:temp ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force -Path $agentTempFolderName | Out-Null

    $agentPackagePath = "$agentTempFolderName\agent.zip"
    $serverUrl = "https://dev.azure.com/$Tenant"
    $vstsAgentUrl = "$serverUrl/_apis/distributedtask/packages/agent/win7-x64?`$top=1&api-version=3.0"
    $vstsUser = "dummy"

    $maxRetries = 3
    $retries = 0
    do
    {
        try
        {
            $basicAuth = ("{0}:{1}" -f $vstsUser, $PAT)
            $basicAuth = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
            $basicAuth = [System.Convert]::ToBase64String($basicAuth)
            $headers = @{ Authorization = ("Basic {0}" -f $basicAuth) }

            $agentList = Invoke-RestMethod -Uri $vstsAgentUrl -Headers $headers -Method Get -ContentType application/json
            $agent = $agentList.value
            if ($agent -is [Array])
            {
                $agent = $agentList.value[0]
            }
            Invoke-WebRequest -Uri $agent.downloadUrl -Headers $headers -Method Get -OutFile "$agentPackagePath" | Out-Null
            break
        }
        catch
        {
            $exceptionText = ($_ | Out-String).Trim()
                
            if (++$retries -gt $maxRetries)
            {
                throw "Failed to download agent due to $exceptionText"
            }
            
            Start-Sleep -Seconds 1 
        }
    }
    while ($retries -le $maxRetries)

    return $agentPackagePath
}

Write-Output "Downloading Devops agent installer package"
$installerPath = Get-AgentInstaller -Tenant $Tenant -PAT $PAT

Write-Output "Installing agent in folder $AgentDirectory"
New-Item -ItemType Directory -Path $AgentDirectory -Force | Out-Null
Expand-Archive -Path $installerPath -DestinationPath $AgentDirectory -Force | Out-Null
Remove-Item -Force -Path $installerPath | Out-Null

Set-Location -Path $AgentDirectory

Write-Output "Configuring Azure Pipelines agent."
.\config.cmd --unattended `
--agent "$AgentName" `
--url "https://dev.azure.com/$Tenant" `
--auth PAT `
--token "$PAT" `
--pool "$agentPool" `
--work "r1" `
--replace `
--runAsAutoLogon `
--overwriteAutoLogon `
--windowsLogonAccount "$VMAdminUser" `
--windowsLogonPassword "$VMAdminPassword" `
--noRestart