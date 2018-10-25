

$currentStart  = $null
$currentEnd = $null
$interval = 15
$ResultSize = 5000
$LogPath = 'C:\Users\yury.samorodov\Downloads\SPOLogs'
$StartDate = Get-Date
$StartDate = $StartDate.Date.AddHours(-48)
$EndDate = $StartDate.AddHours(24)
$ConnectionURI = "https://ps.outlook.com/powershell-LiveID/?proxymethod=RPS"



function SearchUnifiedAuditLog {
    
    $SearchUnifiedAuditLogParameters = @{
        SessionCommand = 'ReturnLargeSet'
        SessionId = New-Guid,
        StartDate = $CurrentStart,
        EndDate = $CurrentEnd,
        FreeText = "sharepoint\.com",
        ResultSize = 5000
    }
    
    Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters
}

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
                $СurrentStart,
                $CurrentEnd,
                $interval,
                $ResultSize
                
            )
            $auditData = @()
            $SessionId = New-Guid
            do {
                
            } while ( $auditData.Count % $ResultSize -eq 0 )
        } -InitializationScript {
           #Import-Module .\New-Office365Session.ps1 ;
            #New-Office365Session 'yuriy.samorodov@veeam.com' 'K@znachey'
            $AdminCredentialParameters = [psobject] @{
                TypeName = 'System.Management.Automation.PSCredential'
                ArgumentList = ( 'svcexchlogcollector@veeam.com' , ( 'LuB&BN0GIrWV' | ConvertTo-SecureString -AsPlainText -Force ) ) 
            }
            $script:AdminCredential =  New-Object @AdminCredentialParameters

            $ExchangeSessionParameters = [psobject] @{
                ConnectionURI = "https://ps.outlook.com/powershell-LiveID/?proxymethod=RPS"
                ConfigurationName = 'Microsoft.Exchange'
                Authentication = 'Basic'
                AllowRedirection = $true    
                Credential = $AdminCredential
            }
            $ExchangeSession = New-PSSession @ExchangeSessionParameters
            Import-PSSession -Session $ExchangeSession -CommandName Search-UnifiedAuditLog -DisableNameChecking | Out-Null
        } -ArgumentList $СurrentStart,$CurrentEnd, $interval,$ResultSize
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