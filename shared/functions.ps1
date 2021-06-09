<#
.SYNOPSIS
    Helper functions needed for infrastructure deployment
#>

Function GetExternalIPAddress(){
    # Returns the public IP of the current host
    Write-Debug "Getting external IP address of the current host."
    $sites = @(
        'http://ipinfo.io/json'
        , 'https://api.ipify.org/?format=json'
        , 'https://icanhazip.com'
        , 'https://ident.me'
        , 'https://ipconfig.me/ip'
    )

    foreach ($site in $sites)
    {
        $serviceIp = $null
        $IPAddress = $null

        $serviceIp = Invoke-RestMethod $site -TimeoutSec 5
        if($null -ne $serviceIp){
            if($serviceIp.psobject.Properties.Name -contains "ip") {
                $IPAddress = [ipaddress]::Parse($serviceIp.ip)
            } else {
                $IPAddress = [ipaddress]::Parse($serviceIp.Trim())
            }

            if($null -ne $IPAddress){
                Write-Debug "Found public IP address $IPAddress."
                return $IPAddress.IPAddressToString
            }
        }
    }
    
    throw "Could not evaluate public IP address."
}

function CreateRdsFirewallException(){
    # Configures a RDS instance to allow local connections
    [CmdletBinding()]
    Param
    (
        # Specifies the identifier of the rds instance
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RdsIdentifier,

        # Specifies the ID of the security group attached to the VPC containing the RDS instance
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SecurityGroupId,

        # Specifies the name of the firewall exception
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ExceptionName = "DeploymentHost",

        # Specifies an IP address to create a firewall exception for
        [Parameter(Mandatory=$true)]
        [System.Net.IPAddress]$IPAddress
    )

    Write-Output "Creating firewall exception DeploymentHost for IP $IPAddress on RDS instance $RdsIdentifier."
    aws ec2 authorize-security-group-ingress `
        --group-id $SecurityGroupId `
        --ip-permissions IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges="[{CidrIp=$IPAddress/32,Description='$ExceptionName'}]"    
    $result = aws rds modify-db-instance --apply-immediately --db-instance-identifier $RdsIdentifier --publicly-accessible
}

Function WaitForRdsFirewallException(){
    # It can take a couple of minutes minutes for new 
    # firewall exceptions to become active after they are created

    [CmdletBinding()]
    Param
    (
        # Specifies the identifier of the rds instance
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RdsIdentifier,
    
        # Specifies the SQL server admin name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SQLAdminUser,
    
        # Specifies the SQL server admin password
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$sqlAdminPassword
    )

    $fqdn = $RdsIdentifier
    
    $waitTime = 30
    $maxRetries = 10

    for ($i = 1; $i -le $maxRetries; $i++) {
        Write-Output "Waiting for RDS instance firewall exception to become active, attempt $i of $maxRetries"
        try
        {
            $pass = ConvertTo-SecureString $sqlAdminPassword -AsPlainText -Force
            $loginCred = New-Object System.Management.Automation.PSCredential($SQLAdminUser, $pass)
        
            Invoke-Sqlcmd -ServerInstance "$fqdn" -Credential $loginCred -Query "SELECT @@version" -ErrorAction Stop
            return
        }
        catch
        {
            Write-Output "Could not connect to the SQL Server instance. Waiting for $waitTime seconds before retrying."
        }

        Start-Sleep -Seconds $waitTime
    }
    throw "Could not connnect to RDS instance after $maxRetries retries."
}

Function RemoveRdslFirewallException(){
    # Removes firewall exception for local connections

    [CmdletBinding()]
    Param
    (
        # Specifies the ID of the security group attached to the VPC containing the RDS instance
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SecurityGroupId,

        # Specifies the name of the firewall exception
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ExceptionName = "DeploymentHost"
    )

    Write-Output "Removing firewall exception $ExceptionName on rds instance $RdsIdentifier."
    $rules = (aws ec2 describe-security-groups --group-ids $SecurityGroupId | ConvertFrom-Json).SecurityGroups.IpPermissions

    foreach ($rule in $rules) {
        $rulematches = $rule.ipranges | Where-Object {$_.Description -eq $ExceptionName}
        foreach ($match in $rulematches) {
            aws ec2 revoke-security-group-ingress `
                --group-id $SecurityGroupId `
                --ip-permissions IpProtocol=$($rule.IpProtocol),FromPort=$($rule.FromPort),ToPort=$($rule.ToPort),IpRanges="[{CidrIp=$($match.CidrIp)}]"
        }
    }
}

Function CreateSqlFirewallException(){
    # Configures SQL server to allow local connections

    [CmdletBinding()]
    Param
    (
        # Specifies the SQL Server name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,

        # Specifies the name of resource group containinig the server
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # Specifies the name of the firewall exception
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ExceptionName = "DeploymentHost",

        # Specifies an IP address to create a firewall exception for
        [Parameter(Mandatory=$true)]
        [System.Net.IPAddress]$IPAddress
    )

    Write-Output "Creating firewall exception DeploymentHost for IP $IPAddress on SQL server $ServerName."
    az sql server update --resource-group $ResourceGroup --name $Servername --enable-public-network true --only-show-errors
    az sql server firewall-rule create --resource-group $ResourceGroup --server $ServerName --name $ExceptionName --start-ip-address $IPAddress.IPAddressToString --end-ip-address $IPAddress.IPAddressToString
}

Function RemoveSqlFirewallException(){
    # Removes firewall exception for local connections

    [CmdletBinding()]
    Param
    (
        # Specifies the SQL Server name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,

        # Specifies the name of resource group containinig the server
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # Specifies the name of the firewall exception to be disabled
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ExceptionName = "DeploymentHost"
    )

    Write-Output "Removing firewall exception $ExceptionName on SQL server $ServerName."
    az sql server update --resource-group $ResourceGroup --name $servername --enable-public-network false --only-show-errors
    az sql server firewall-rule delete --resource-group $ResourceGroup --server $serverName --name $ExceptionName
}

Function WaitForSQLFirewallException(){
    # It can take a couple of minutes minutes for new 
    # firewall exceptions to become active after they are created

    [CmdletBinding()]
    Param
    (
        # Specifies the SQL Server Name used by Tosca
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,
    
        # Specifies the name of the resource group containinig the SQL server
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,
    
        # Specifies the database name used by Tosca
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DBName,
    
        # Specifies the SQL server admin name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SQLAdminUser,
    
        # Specifies the SQL server admin password
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$sqlAdminPassword
    )

    $fqdn = "$Servername.database.windows.net"
    $connString = "Server=tcp:$fqdn,1433;Initial Catalog=$DBName;Persist Security Info=False;User ID=$SQLAdminUser;Password=$sqlAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    $waitTime = 30
    $maxRetries = 20

    for ($i = 1; $i -le $maxRetries; $i++) {
        Write-Output "Waiting for Azure SQL firewall exception to become active, attempt $i of $maxRetries"
        try
        {
            $pass = ConvertTo-SecureString $sqlAdminPassword -AsPlainText -Force
            $loginCred = New-Object System.Management.Automation.PSCredential($SQLAdminUser, $pass)
        
            $sqlQuery = "SELECT @@version"
            Invoke-Sqlcmd -ServerInstance $fqdn -Database $DBName -Query $sqlQuery -Credential $loginCred -ErrorAction Stop
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connString
            $conn.Open()
            if($conn.State -eq "Open")
            {
                Write-Host "Successfully connected to the SQL server."
                $conn.Close()
                return
            }
        }
        catch
        {
            Write-Output "Could not connect to the SQL Server instance. Waiting for $waitTime seconds before retrying."
        }

        Start-Sleep -Seconds $waitTime
    }
    throw "Could not connnect to Azure SQL after $maxRetries retries."
}

Function CreateToscaSQLUser(){
    # Creates a new SQL user for tosca

    [CmdletBinding()]
    Param
    (
        # Specifies the SQL Server Name used by Tosca
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,

        # Specifies the name of the resource group containinig the SQL server
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # Specifies the database name used by Tosca
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DBName,

        # Specifies the SQL server admin name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SQLAdminUser,

        # Specifies the SQL server admin password
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SQLAdminPassword,

        # Specifies the name of the user that will be created
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        # Specifies the password of the user that will be created
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password
    )

    Write-Output "Creating SQL login $Username"

    try {
        $pass = ConvertTo-SecureString $sqlAdminPassword -AsPlainText -Force
        $loginCred = New-Object System.Management.Automation.PSCredential($SQLAdminUser, $pass)

        $sqlQuery = "CREATE LOGIN $Username WITH password='$Password';" 
        Invoke-Sqlcmd -ServerInstance $fqdn -Database master -Query $sqlQuery -Credential $loginCred
    }
    catch {
        throw "An error occurred while creating SQL login $Username : $($_.Exception)"
    } 

    Write-Output "Mapping login to database $dbName"

    $sqlQuery = "
        CREATE USER $Username FROM LOGIN $Username;
        GO
        EXEC sp_addrolemember 'db_datareader', '$Username';
        GO
        EXEC sp_addrolemember 'db_datawriter', '$Username';
        GO
    "
    try {
        Invoke-Sqlcmd -ServerInstance $fqdn -Database $dbName -Query $sqlQuery -Credential $loginCred
    }
    catch {
        throw "An error occurred while mapping login $Username to database $dbName : $($_.Exception)"
    } 
}

Function VerifyFile(){
    # Checks if a file exists
    [CmdletBinding()]
    Param
    (
        # Specifies the path to the file
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    if(-not (Test-Path -Path $FilePath)){
        throw "Could not find file $filePath"
    }
}

Function CreateSaFirewallException(){
    # Configures storage account to allow local connections
    # While it's more secure to only allow a single IP, it can
    # cause the upload to fail under certain conditions, see
    # https://github.com/MicrosoftDocs/azure-docs/issues/19456

    [CmdletBinding()]
    Param
    (
        # Specifies the storage account name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SaName,

        # Specifies the name of resource group containinig the storage account
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # Specifies an IP address to create a firewall exception for
        # If no IP is provided, the account will be set to allow public access
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [System.Net.IPAddress]$IPAddress
    )

    if($null -eq $IPAddress){
        Write-Output "Configuring storage account $SaName to allow public blob access."
        az storage account update --resource-group $ResourceGroup --name $SaName --default-action 'Allow' | Out-Null
    } else {
        Write-Output "Creating firewall exception on storage account $SaName for IP $IPAddress"
        az storage account network-rule add --resource-group $ResourceGroup --account-name $SaName --action allow --ip-address $IPAddress.IPAddressToString | Out-Null
    }
}

Function RemoveSaFirewallException(){
    # Removes firewall exception for local connections

    [CmdletBinding()]
    Param
    (
        # Specifies the storage account name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SaName,

        # Specifies the name of resource group containinig the storage account
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # Specifies an IP address to create a firewall exception for
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [System.Net.IPAddress]$IPAddress
    )
    Write-Output "Setting storage account $SaName to deny public blob access."
    az storage account update --resource-group $ResourceGroup --name $SaName --default-action 'Deny' | Out-Null

    if($null -ne $IPAddress){
        Write-Output "Removing firewall exception on storage account $SaName for IP $IPAddress."
        az storage account network-rule remove --resource-group $ResourceGroup --account-name $SaName --ip-address $IPAddress.IPAddressToString | Out-Null
    }
}

Function CreateNsgFirewallException(){
    # Create an NSG firewall exception

    [CmdletBinding()]
    Param
    (
        # Specifies the NSG ID
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$NsgId,

        # Specifies the name of the rule name to create
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RuleName,

        # Specifies the port or port range for the exception
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Port,

        # Specifies the protocol for the exception
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Protocol,

        # Specifies the IP address for the exception
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Net.IPAddress]$IPAddress
    )

    Write-Output "Creating Network Security Group exception $RuleName."

    $nsg = az network nsg show --ids $NsgId | ConvertFrom-Json

    # get free firewall rule index
    $nsgRules =  ($nsg.securityRules | Sort-Object -Property priority).priority
    $nsgRulePriority = 100
    
    while ($nsgRulePriority -lt 65000)
    {
        if($nsgRules -contains $nsgRulePriority){
            $nsgRulePriority++
            continue
        }
        break
    }
    az network nsg rule create `
        --resource-group $nsg.resourceGroup `
        --nsg-name $nsg.name `
        --priority $nsgRulePriority `
        --name $RuleName `
        --access allow `
        --direction inbound `
        --protocol $Protocol `
        --source-address-prefixes $IPAddress.IPAddressToString `
        --source-port-ranges '*' `
        --destination-address-prefixes '*' `
        --destination-port-ranges $Port |
        Out-Null
}

Function RemoveNsgFirewallException(){
    # Removes a NSG firewall exception

    [CmdletBinding()]
    Param
    (
        # Specifies the NSG ID
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$NsgId,

        # Specifies the rule name to delete
        [Parameter(Mandatory=$false)]
        [string]$RuleName
    )
    Write-Output "Removing firewall exception $RuleName on Network Security Group $NsgName."

    $nsg = az network nsg show --ids $NsgId | ConvertFrom-Json
    az network nsg rule delete --resource-group $nsg.resourcegroup --nsg-name $nsg.name --name $RuleName
}

Function WaitForSaFirewallException(){
    # It can take a couple of seconds for new sa firewall exceptions
    # to become active once they are created. 
    # The function will delay the execution of further steps, but will exit early if a connection
    # is successful during the wait time

    [CmdletBinding()]
    Param
    (
        # Specifies the service account name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SaName,
    
        # Specifies the primary or secondary account key of the storage account
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key
    )
    $waitTime = 10
    $maxRetries = 120

    for ($i = 1; $i -le $maxRetries; $i++) {
        Write-Output "Waiting for storage account firewall exception to become active, attempt $i of $maxRetries"
        $msg = az storage container list --account-name $saName --account-key $key 2>&1
        if($? -eq $true){
            Write-Host "Successfully connected to storage account."
            return
        }

        Start-Sleep -Seconds $waitTime
    }
    throw "Could not connnect to the storage account after $maxRetries retries: $msg"
}

Function CreateRandomString(){
    [CmdletBinding()]
    Param
    (
        # Specifies the lenght of the created password
        [Parameter(Mandatory=$false)]
        [ValidateRange(5,128)]
        [int]$Length = 50
    )

    $lower = 'abcdefghiklmnoprstuvwxyz'
    $upper = 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $numeral = '1234567890'
    $special = '!§%=?@#*+'
    $characters = ($lower + $upper + $numeral + $special)

    # Make sure that at least one chracter of each class is included
    $pw = $lower[(get-random -Maximum $lower.length)]
    $pw += $upper[(get-random -Maximum $upper.length)]
    $pw += $numeral[(get-random -Maximum $numeral.length)]
    $pw += $special[(get-random -Maximum $special.length)]

    for ($i = 1; $i -lt ($Length - 3); $i++)
    { 
        $pw += $characters[(get-random -Maximum $characters.length)]
    }

    return (($pw -split '' | Sort-Object {Get-Random}) -join '').Trim()
}

Function EnsureResourceGroupExists(){
    # Check if a resource group exists, attempt to create it otherwise
    # Returns resource group object

    [CmdletBinding()]
    Param
    (
        # Specifies the name of the resource group to check
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $rgExists = az group exists --name $Name 2>&1

    if($? -eq $false){
        throw "An error occurred while attempting to verify the existence of resource group $Name : $($msg.Exception.Message)"
    }

    if($rgExists -eq "false"){
        Write-Output "Creating resource group $Name."
        $msg = az group create --name $Name --location $deploymentParameters.location.value 2>&1

        if($? -eq $false){
            throw "Could not create resource group $Name : $($msg.Exception.Message)"
        }
    }

    $rg = az group show --name $Name | ConvertFrom-Json
    return $rg
}

Function EnsureDeploymentRoles(){
    # Check if a user has contributor or owner permissions on a resource group,
    # attempts to set the contributor role if not

    [CmdletBinding()]
    Param
    (
        # Specifies scope ID to check
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Scope,

        # Specifies user ID to check for
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserId
    )

    $roles = az role assignment list --scope $Scope --include-inherited --include-groups --assignee $UserId | ConvertFrom-Json
    if($roles.roleDefinitionName -notcontains "contributor" -and $roles.roleDefinitionName -notcontains "owner"){
        Write-Output "User ID $UserId does not sufficient permissions to deploy resources in scope $Scope. Attempting to add the contributor role."
        $msg = az role assignment create --role "contributor" --assignee $sp.appId --scope $Scope 2>&1
        if($? -eq $false){
            throw "Error while adding roles: $($msg.Exception.Message)"
        }
    }
}

Function ParseTerraformTfvars(){
    # Parses the provided terraform variable file and returns
    # a powershell object containing all variables inside
    [CmdletBinding()]
    Param
    (
        # Specifies the path to a tfvars file
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Array]$TfvarsPath
    )

    $parsedOutput = @{}

    $pattern = '(.*)\s?=\s?(.*)'
    $regex = Select-String -Path $TfvarsPath -Pattern $pattern -AllMatches
    foreach ($item in $regex.Matches) {
        $parsedOutput += @{$item.Groups[1].Value.trim() = $item.Groups[2].Value.trim().trim('"')}
    }
    return $parsedOutput
}

Function DiscoverAzureVnet(){
    # Tries to auto-discover the tosca environment vnet in the provided resource group
    [CmdletBinding()]
    Param
    (
        # Specifies the name of the resource group to check in
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup
    )

    $vnets = az network vnet list --resource-group $ResourceGroup | ConvertFrom-Json
    if($vnets.length -lt 1){
        throw "Could not find virtual network in resource group $ResourceGroup."
    }

    if($vnets.length -gt 1){
        throw "Found multiple virtual networks in resource group $ResourceGroup."
    }

    $vnet = $vnets | Select-Object -First 1
    # Make sure that the vnet has the needed subnets

    $clientSubnet = az network vnet subnet show --resource-group $ResourceGroup --vnet-name $vnet.name --name clients | ConvertFrom-Json

    if($null -eq $clientSubnet){
        throw "Could not find clients subnet in virtual netowrk $($vnet.name)."
    }

    $servicesSubnet = az network vnet subnet show --resource-group $ResourceGroup --vnet-name $vnet.name --name services | ConvertFrom-Json

    if($null -eq $servicesSubnet){
        throw "Could not find services subnet in virtual netowrk $($vnet.name)."
    }

    return $vnet
}

Function DiscoverAzureStorageAccount(){
    # Tries to auto-discover the tosca environment storage account in the provided resource group
    [CmdletBinding()]
    Param
    (
        # Specifies the name of the resource group to check in
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup
    )

    # $sa = az storage account list --resource-group $ResourceGroup | ConvertFrom-Json
    $sa = az storage account list | ConvertFrom-Json | Where-Object {$_.resourcegroup -eq $ResourceGroup}
    if($sa.length -lt 1){
        throw "Could not find storage account in resource group $ResourceGroup."
    }

    if($sa.length -gt 1){
        throw "Found multiple storage accounts in resource group $ResourceGroup."
    }
    
    return ($sa | Select-Object -First 1)
}

Function ParseStorageAccountUri(){
    # Tries to parse storage account details from the url of a file
    [CmdletBinding()]
    Param
    (
        # URI to a file uploaded to a storage account
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri
    )

    $saRegex = '(?:https?:\/\/)?(.*).blob.core.windows.net\/(.*)\/(.*)'

    $found = $Uri -match $saRegex
    if($found -eq $false){
        throw "Could not parse URI $Uri using regular expression $saRegex"
    }

    return [PSCustomObject]@{
        Uri = $Uri
        Name = $Matches[1]
        Container = $Matches[2]
        FileName = $Matches[3]
        Sas = $null
    }
}

Function GenerateSaSas(){
    # Creates a storage account shared access token
    [CmdletBinding()]
    Param
    (
        # Specifies the name of the resource group containing the storage account.
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # Specifies the name of the storage account.
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageAccount,

        # Specifies the validity of the sas in hours.
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int]$ValidFor,

        # Specifies a permission set for the sas.
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Permissions = 'lpr'
    )

    $connectionString =  (az storage account show-connection-string --resource-group $ResourceGroup --name $StorageAccount | ConvertFrom-Json).connectionString
    if([string]::IsNullOrWhiteSpace($connectionString)){
        throw "An issue was encountered while getting the connection string for storage account $storageAccount."
    }

    $connectionString = $connectionString.Trim("'")
    $connectionString = "'$connectionString'"

    $sas = az storage account generate-sas `
        --expiry ((Get-Date).AddHours($ValidFor).ToString("yyyy-MM-ddTHH:mmZ")) `
        --services b `
        --resource-types sco `
        --permissions $Permissions `
        --account-name $StorageAccount `
        --connection-string $connectionString

    if([string]::IsNullOrWhiteSpace($sas)){
        throw "An issue was encountered while generating a shared access signature for storage account $storageAccount."
    }

    return $sas.trim('"')
}