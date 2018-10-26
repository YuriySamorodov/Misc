$scriptStart = Get-Date
Get-Job | Remove-Job
$currentStart  = $null
$currentEnd = $null
$interval = 15
$ResultSize = 5000

$LogPath = 'C:\Users\yury.samorodov\Downloads\SPOLogs'
$StartDate = Get-Date
$StartDate = $StartDate.Date.AddHours(-48)
$EndDate = $StartDate.AddHours(1)
$ConnectionURI = "https://ps.outlook.com/powershell-LiveID/?proxymethod=RPS"

do  {
    #Date Managemment
    if ($CurrentStart -eq $null) {
            $CurrentStart = $StartDate
        }

    $jobs = @()
    Get-Job | Remove-Job
    #Getting log data in an hour timespan using 15 minutes chunks

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
            #OutVariable = '+data'
        }
        $jobs += Start-Job -Name $JobName -ScriptBlock {
            param ($PassedArgs)
            $data = New-Object System.Collections.ArrayList
            #Search-UnifiedAuditLog @PassedArgs -outvariable +data
            #Write-Host $data
            do {
                #$ErrorActionPreference = 'Stop'
                #$AuditData += SearchUnifiedAuditLog -CurrentStart $CurrentStart -CurrentEnd $CurrentEnd
                try {
                    Search-UnifiedAuditLog @PassedArgs -outvariable +data
                }
                catch {
                    #Write-Host $($error[0])
                    Get-PSSession | Remove-PSSession
                    Connect-Exchange 'svcexchlogcollector@veeam.com' 'LuB&BN0GIrWV'
                    Search-UnifiedAuditLog @PassedArgs -outvariable +data
                }
                finally {
                    $localResults = Get-Job | Receive-Job -Keep
                }
            } while ( $localResults[-1].ResultIndex -ne $localResults[-1].ResultCount )
        } -InitializationScript {
            Import-Module .\Connect-Exchange.ps1 ;
            #Connect-Exchange 'svcexchlogcollector@veeam.com' 'LuB&BN0GIrWV' ;
            #Connect-Exchange 'yuriy.samorodov@veeam.com' 'K@znachey' ;
            #Import-Module .\Search-O365UnifiedAuditLogs.ps1 ;
        } -ArgumentList $SearchUnifiedAuditLogParameters,$data
        #Write-Host $JobName
        #Write-Output $Jobs
        Get-PSSession | Remove-PSSession
        $i = $i + $interval
        $CurrentStart = $CurrentEnd
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
        Get-Job | Remove-Job
        Start-Sleep -Seconds 60
        #$Jobs = @()
    }
} while ( 
    $currentStart -le $EndDate
)
$scriptEnd = Get-Date
Write-Host "Total Run time: $($scriptEnd - $scriptStart"
