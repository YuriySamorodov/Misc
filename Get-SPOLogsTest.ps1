function Start-O365UnifiedAuditLogSearch {
    $scriptStart = Get-Date

    $jobs = @()
    Get-Job | Remove-Job -Force
    $currentStart  = $null
    $currentEnd = $null
    $interval = 15
    $ResultSize = 5000

    $LogPath = "C:\Users\yury.samorodov\Downloads\SPOLogs"
    $StartDate = Get-Date
    $StartDate = $StartDate.Date.AddHours(-72)
    $EndDate = $StartDate.AddHours(24)
    $ConnectionURI = "https://ps.outlook.com/powershell-LiveID/?proxymethod=RPS"



    do  {
        #Date ManagemmentX
        if ($CurrentStart -eq $null) {
                $CurrentStart = $StartDate
            }
        #Get-Job | Remove-Job -Force
        #Getting log data in an hour timespan using 15 minutes chunks

        $scriptStart = Get-Date

        for ($i = 0 ; $i -lt 60) {
            $AuditData = New-Object System.Collections.ArrayList
            $SessionId = New-Guid
            $CurrentEnd = $CurrentStart.AddMinutes($interval)
            $JobName = "SPOLogs_$($CurrentStart.ToString("yyyyMMddHH"))00"
            $SearchUnifiedAuditLogParameters = @{
                SessionId = $SessionId
                StartDate = $CurrentStart
                EndDate = $CurrentEnd
                SessionCommand = 'ReturnLargeSet'
                FreeText = "sharepoint\.com"
                ResultSize = $ResultSize
                ErrorAction = 'Stop'
                OutVariable = '+data'
            }
            if ( ( Get-Job ).Count -lt 6 ) {
                Start-Job -Name $JobName -ScriptBlock {
                    param ($PassedArgs,$LogPath,$JobName, $ResultSize )
                    #$data = New-Object System.Collections.ArrayList
                    do {                    
                        try {
                            #Search-UnifiedAuditLog @PassedArgs #-outvariable +data
                            if ( $data[-1].ResultCount -eq 0 -or $data.Count -eq 0 -or ( $data | where { $_.ResultIndex -eq 1 } ).Count -gt 1 ) 
                            { 
                                throw
                            }   
                        } catch {
                            #$data = New-Object System.Collections.ArrayList
                            Get-PSSession | Remove-PSSession
                            Connect-Exchange 'svcexchlogcollector@veeam.com' 'LuB&BN0GIrWV'
                            #Connect-Exchange 'yuriy.samorodov@veeam.com' 'K@znachey'
                        } finally {
                            $data = New-Object System.Collections.ArrayList
                            Search-UnifiedAuditLog @PassedArgs #-outvariable +data
                            # Start-Sleep -Milliseconds 500
                            #$lastIndex = $data[-1].ResultIndex
                            #$data = $data | Sort-Object ResultIndex
                        }
                    } 
                    while ($data[-1].ResultIndex -ne $data[-1].ResultCount -or ( $data | where { $_.ResultIndex -eq 1 } ).Count -ge 3 )

                } -InitializationScript {
                    Import-Module "C:\Users\yury.samorodov\github\Misc\Connect-Exchange.ps1" ;
                } -ArgumentList $SearchUnifiedAuditLogParameters,$LogPath,$JobName,$ResultSize
                Get-PSSession | Remove-PSSession
                $i = $i + $interval
                $CurrentStart = $CurrentEnd
            } elseif ( ( $CompletedJobs = Get-Job -State Completed ).Count -ge 1 ) {
                Write-Output "Exporting data for $( $CompletedJobs.Count ) jobs"
                foreach ($item in $CompletedJobs ){
                    $results = $item | Receive-Job
                    $results = $results | Select-Object -ExpandProperty AuditData
                    $results = $results | ConvertFrom-Json
                    $results = [Linq.Enumerable]::Distinct([array[]]$results)
                    $results.SyncRoot | export-csv -NoTypeInformation "$($LogPath)\$($item.name).log" -Append -Force
                    $completedJobs | Remove-Job -ea:0
                    Start-Sleep -Milliseconds 500
                    }
                     continue
            } else {
                # Write-Output "Nothing to export. Moving on..."
                continue
            }
<<<<<<< HEAD
            $ExchangeSession = New-PSSession @ExchangeSessionParameters
            Import-PSSession -Session $ExchangeSession -CommandName Search-UnifiedAuditLog | Out-Null
        } -ArgumentList $interval,$startDate,$ResultSize
        Get-PSSession | Remove-PSSession
        $i = $i + $interval
    }
    if ($jobs.Count -eq 12) {
        $JobsGroups = $jobs | group Name | select -ExpandProperty Name
        foreach ( 
            $gr
        )
        $jobs | Wait-Job | Out-Null
        $jobs | Remove-Job
        $results = $results | Select-Object -ExpandProperty AuditData
        $results = $results | ConvertFrom-Json
        $results | export-csv -NoTypeInformation "$($JobName).log" -Append
        Start-Sleep -Seconds 60
=======
        }

        $lastJobs = Get-Job | Where-Object { $_.State -ne 'Running'} 

        if ( $lastJobs.Count -gt 0 ) {
            foreach ( $item in $lastJobs ) {
                $result = $item | Receive-Job
                $result = $result | Select-Object -ExpandProperty AuditData
                $result = $result | ConvertFrom-Json
                $result = [Linq.Enumerable]::Distinct([array[]]$results)
                $result | export-csv -NoTypeInformation "$($LogPath)\$($item.Name).log" -Append -Force
                $lastJobs | Remove-Job -ea:0
                Start-Sleep -Milliseconds 500
            }
        }

        $scriptEnd = Get-Date
        Write-Output "Creating $Jobname job completed"


        #$jobs = Get-Job
<#        
        do {
            foreach ( $job in Get-Job -State Completed ) {
                $results = Receive-Job $job 
                $results = $results | Select-Object -Unique
                $results = $results | Select-Object -ExpandProperty AuditData
                $results = $results | ConvertFrom-Json
                $results | export-csv -NoTypeInformation "$($LogPath)\$($job.Name).log" -Append -Force
            }
            Get-Job | Remove-Job -ea:0
            Start-Sleep -Milliseconds 500
        } until (
            ( Get-Job ).Count -lt 6
        )   
        #>
<#
        if ($jobs.Count -eq 12 ) {
            $jobs | Wait-Job | Out-Null
            $JobGroups = $jobs | Group-Object Name
            $JobGroups = $JobGroups | Select-Object -ExpandProperty Name
            foreach ($JobGroup in $JobGroups) {
                #$JobGroup | Wait-Job | Out-Null
                $results = Get-Job $JobGroup
                $results = $results | Receive-Job
                $results = $results | Select-Object -ExpandProperty AuditData
                $results = $results | ConvertFrom-Json
                $results | export-csv -NoTypeInformation "$($LogPath)\$($JobGroup).log" -Append
            }
            Get-Job | Remove-Job
            #Start-Sleep -Seconds 60
            $Jobs = @()
        }

 #>
        #Get-Job | Remove-Job
 
    } 
    
    while ( 
        $currentStart -le $EndDate
    )

<#
do {
    foreach ( $job in Get-Job -State Completed ) {
        $results = Receive-Job $job 
        $results = $results | Select-Object -Unique
        $results = $results | Select-Object -ExpandProperty AuditData
        $results = $results | ConvertFrom-Json
        $results | export-csv -NoTypeInformation "$($LogPath)\$($job.Name).log" -Append -Force
>>>>>>> b6cca9a139812dd3b94b534cb2fe03b5b6afd139
    }
    Get-Job | Remove-Job -ea:0
    Start-Sleep -Milliseconds 500
} while (Get-Job)
#>

$scriptEnd = Get-Date
Write-Output "Total time to complete: $($($scriptEnd - $scriptStart).ToString("hh\:mm\:ss"))"
}
