

$currentStart  = $null
$currentEnd = $null
$interval = 15
$ResultSize = 5000
$LogPath = 'C:\Users\yury.samorodov\Downloads\SPOLogs'
$StartDate = Get-Date
$StartDate = $StartDate.Date.AddHours(-48)
$EndDate = $StartDate.AddHours(24)
$ConnectionURI = "https://ps.outlook.com/powershell-LiveID/?proxymethod=RPS"

$jobs = @()
do  {
    #Date Managemment
    if ($CurrentStart -eq $null) {
                $CurrentStart = $StartDate
            } else {
                $CurrentStart = $CurrentStart.AddHours(1)    
            }
    $CurrentEnd = $CurrentStart.AddMinutes($interval)
    
    #Getting log data in an hour timespan using 15 minutes chunks
    for ($i = 0 ; $i -lt 60) {
        $JobName = "SPOLogs_$($CurrentStart.ToString("yyyyMMddHHmm"))"
        $jobs += Start-Job -Name $JobName -ScriptBlock {   
            param (
                $CurrentStart,
                $ResultSize
            )
            do {
                $AuditData += SearchUnifiedAuditLog
            } while ( $AuditData.Count % 5000 -eq 0 )
        } -InitializationScript {
            Import-Module .\Connect-Exchange.ps1 ;
            Connect-Exchange 'yuriy.samorodov@veeam.com' 'K@znachey' ;
            Import-Module .\Search-O365UnifiedAuditLogs.ps1 ;
        } -ArgumentList $СurrentStart,$ResultSize
        Write-Host $JobName
        #Write-Output $Jobs
        Get-PSSession | Remove-PSSession
        $i = $i + $interval
    }
    if ($jobs.Count -eq 12) {
        $jobs | Wait-Job | Out-Null
        $JobGroups = $jobs | Group-Object Name
        $JobGroups = $JobGroups | Select-Object -ExpandProperty Name
        foreach ($JobGroup in $JobGroups) {
            $results = Get-Job $JobGroup
            $results = $results | Receive-Job
            $results = $results | Select-Object -ExpandProperty AuditData
            $results = $results | ConvertFrom-Json
            $results | export-csv -NoTypeInformation "$($LogPath)\$($JobName).log" -Append
        }
        $jobs | Remove-Job
        Start-Sleep -Seconds 60
    }
} while ( 
    $currentStart -le $EndDate
)