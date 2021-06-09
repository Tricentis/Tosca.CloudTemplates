<#
.Synopsis
   Installs Tricentis Tosca
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

Write-Output "Installing Tricentis Tosca."
Write-Output "Using setup type $($env:tosca_setup_type)."

try {
   Set-Location $env:Temp
   Write-Output "Downloading setup from from $(($env:tosca_setup_path).split('?')[0])"
   $destination = Join-Path -Path $env:TEMP -ChildPath "toscasetup.exe"
   Get-FileFromURL -URL $env:tosca_setup_path -Filename $destination   
}
catch {
   throw "An Error occurred while downloading the file: $($_.Exception)"
}

switch ($env:tosca_setup_type) {
   { $_ -in "ToscaCommander", "ToscaServer" } { 
      Write-Output "Installing Tricentis Tosca with installation type Tosca Commander."
      .\toscasetup.exe /s DIAGNOSTICS=1 ENABLE_TOSCA_BI=1 EXAMPLE_WORKSPACES=1 MOBILE_TESTING=1 OCRDB=1 START_SERVICES=0 NETDRIVE=0 INSTALLDIR="C:\Program Files (x86)\TRICENTIS\Tosca Testsuite" TOSCA_PROJECTS="C:\Tosca_Projects" TRICENTIS_ALLUSERS_APPDATA="C:\ProgramData\TRICENTIS\Tosca Testsuite\7.0.0" /qn | Out-Default
   }
   "DexAgent" { 
      Write-Output "Installing Tricentis Tosca with installation type Dex Agent."
      .\toscasetup.exe /s DIAGNOSTICS=1 ENABLE_TOSCA_BI=0 EXAMPLE_WORKSPACES=0 MOBILE_TESTING=0 OCRDB=0 START_SERVICES=0 NETDRIVE=0 ADDLOCAL=TricentisTBox, DexAgent INSTALLDIR="C:\Program Files (x86)\TRICENTIS\Tosca Testsuite" TOSCA_PROJECTS="C:\Tosca_Projects" TRICENTIS_ALLUSERS_APPDATA="C:\ProgramData\TRICENTIS\Tosca Testsuite\7.0.0" /qn | Out-Default
   }
   Default {
      throw 'Unknown tosca_setup_type $($env:tosca_setup_type) was provided.'
   }
}

Remove-Item -Path .\toscasetup.exe -Force -ErrorAction Ignore -Verbose