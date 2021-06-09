<#
.Synopsis
   Installs Tosca server
#>

function Get-FileFromURL {
   # https://stackoverflow.com/questions/46830703
   [CmdletBinding()]
   param(
       [Parameter(Mandatory, Position = 0)]
       [System.Uri]$URL,
       [Parameter(Mandatory, Position = 1)]
       [string]$Filename
   )

   process {
       try {
           $request = [System.Net.HttpWebRequest]::Create($URL)
           $request.set_Timeout(5000) # 5 second timeout
           $response = $request.GetResponse()
           $total_bytes = $response.ContentLength
           $response_stream = $response.GetResponseStream()

           try {
               # 256KB works better on my machine for 1GB and 10GB files
               # See https://www.microsoft.com/en-us/research/wp-content/uploads/2004/12/tr-2004-136.pdf
               # Cf. https://stackoverflow.com/a/3034155/10504393
               $buffer = New-Object -TypeName byte[] -ArgumentList 256KB
               $target_stream = [System.IO.File]::Create($Filename)

               $timer = New-Object -TypeName timers.timer
               $timer.Interval = 1000 # Update progress every second
               $timer_event = Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action {
                   $Global:update_progress = $true
               }
               $timer.Start()

               do {
                   $count = $response_stream.Read($buffer, 0, $buffer.length)
                   $target_stream.Write($buffer, 0, $count)
                   $downloaded_bytes = $downloaded_bytes + $count

                   if ($Global:update_progress) {
                       $percent = $downloaded_bytes / $total_bytes
                       $status = @{
                           completed  = "{0,6:p2} Completed" -f $percent
                           downloaded = "{0:n0} MB of {1:n0} MB" -f ($downloaded_bytes / 1MB), ($total_bytes / 1MB)
                           speed      = "{0,7:n0} KB/s" -f (($downloaded_bytes - $prev_downloaded_bytes) / 1KB)
                           eta        = "eta {0:hh\:mm\:ss}" -f (New-TimeSpan -Seconds (($total_bytes - $downloaded_bytes) / ($downloaded_bytes - $prev_downloaded_bytes)))
                       }
                       $progress_args = @{
                           Activity        = "Downloading $URL"
                           Status          = "$($status.completed) ($($status.downloaded)) $($status.speed) $($status.eta)"
                           PercentComplete = $percent * 100
                       }
                       Write-Progress @progress_args

                       $prev_downloaded_bytes = $downloaded_bytes
                       $Global:update_progress = $false
                   }
               } while ($count -gt 0)
           }
           finally {
               if ($timer) { $timer.Stop() }
               if ($timer_event) { Unregister-Event -SubscriptionId $timer_event.Id }
               if ($target_stream) { $target_stream.Dispose() }
               # If file exists and $count is not zero or $null, than script was interrupted by user
               if ((Test-Path $Filename) -and $count) { Remove-Item -Path $Filename }
           }
       }
       finally {
           if ($response) { $response.Dispose() }
           if ($response_stream) { $response_stream.Dispose() }
       }
   }
}

Write-Output "Installing Tricentis Tosca Server."

try {
   Set-Location $env:Temp
   Write-Output "Downloading setup from from $(($env:toscaserver_setup_path).split('?')[0])"
   $destination = Join-Path -Path $env:TEMP -ChildPath "toscaserversetup.exe"
   Get-FileFromURL -URL $env:toscaserver_setup_path -Filename $destination   
}
catch {
   throw "An Error occurred while downloading the file: $($_.Exception)"
}

Write-Output "Installing Tosca Server."
.\toscaserversetup.exe /s /V"DATADIR=C:\ProgramData\TRICENTIS\ToscaServer\Logs USE_HTTPS=1 LANDINGPAGE_PORT=443 ADDLOCAL=ALL /qn" | Out-Default

Import-Module WebAdministration
Stop-Website -Name "Default Web Site"

Remove-Item -Path .\toscaserversetup.exe -Force -ErrorAction Ignore -Verbose