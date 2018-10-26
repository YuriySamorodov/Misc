Get-Job | Remove-Job
$currentStart  = $null
$currentEnd = $null
$interval = 15
$ResultSize = 5000

$LogPath = 'C:\Users\yury.samorodov\Downloads\SPOLogs'
$StartDate = Get-Date
$StartDate = $StartDate.Date.AddHours(-48)
$EndDate = $StartDate.AddHours(24)
$ConnectionURI = "https://ps.outlook.com/powershell-LiveID/?proxymethod=RPS"

do  {
    #Date Managemment
    if ($CurrentStart -eq $null) {
            $CurrentStart = $StartDate
        }
    
    #Getting log data in an hour timespan using 15 minutes chunks
    $scriptStart = Get-Date
    for ($i = 0 ; $i -lt 60) {
        $AuditData = New-Object System.Collections.ArrayList
        $SessionId = New-Guid
        $CurrentEnd = $CurrentStart.AddMinutes($interval)
        $JobName = "SPOLogs_$($CurrentStart.ToString("yyyyMMddHHmm"))"
        $SearchUnifiedAuditLogParameters = @{
            SessionId = $SessionId
            StartDate = $CurrentStart
            EndDate = $CurrentEnd
            SessionCommand = 'ReturnLargeSet'
            FreeText = "sharepoint\.com"
            ResultSize = $ResultSize
            #OutVariable = '+data'
        }
        Start-Job -Name $JobName -ScriptBlock {
            param ($PassedArgs)
            $data = New-Object System.Collections.ArrayList
            Search-UnifiedAuditLog @PassedArgs -outvariable +data
            #Write-Host $data
            do {
                #$AuditData += SearchUnifiedAuditLog -CurrentStart $CurrentStart -CurrentEnd $CurrentEnd
                Search-UnifiedAuditLog @PassedArgs -outvariable +data
            } while ( $data.Count % 5000 -eq 0 )
        } -InitializationScript {
            Import-Module .\Connect-Exchange.ps1 ;
            Connect-Exchange 'svcexchlogcollector@veeam.com' 'LuB&BN0GIrWV' ;
            #Connect-Exchange 'yuriy.samorodov@veeam.com' 'K@znachey' ;
            #Import-Module .\Search-O365UnifiedAuditLogs.ps1 ;
        } -ArgumentList $SearchUnifiedAuditLogParameters,$data
        #Write-Host $JobName
        #Write-Output $Jobs
        Get-PSSession | Remove-PSSession
        $i = $i + $interval
        $CurrentStart = $CurrentEnd
    }
    $scriptEnd = Get-Date

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
        Get-Job | Remove-Job
        Start-Sleep -Seconds 60
        $Jobs = @()
    }
} while ( 
    $currentStart -le $EndDate
)