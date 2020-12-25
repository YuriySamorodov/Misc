param (
    $StartDate,
    $EndDate
)

$interval = 15
$ResultSize = 5000

do  {
    for ($i = 0 ; $i -lt 60) {
        $JobName = "SPOLogs$($EndDate.ToString("yyyyMMddHHmm"))"
        $jobs = @()
        $jobs += Start-Job -Name $JobName -ScriptBlock {   
            param (
                $StartDate,
                $interval,
                $ResultSize
                
            )
            $auditData = @()
            $SessionId = New-Guid
            do {
                if ($CurrentStart -eq $null) {
                    $CurrentStart = $StartDate
                }
                $CurrentEnd = $CurrentStart.AddMinutes($interval)
                $SearchUnifiedAuditLogParameters = @{
                    SessionCommand = 'ReturnLargeSet'
                    SessionId = $SessionId
                    StartDate = $CurrentStart
                    EndDate = $CurrentEnd
                    FreeText = "sharepoint\.com"
                    ResultSize = $ResultSize
                }
                Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters
            } while ( $auditData.Count % $ResultSize -eq 0 )
        } -InitializationScript {
           #Import-Module .\New-Office365Session.ps1 ;
            #New-Office365Session 'yuriy.samorodov@veeam.com' 'K@znachey'
            $AdminCredentialParameters = [psobject] @{
                TypeName = 'System.Management.Automation.PSCredential'
                ArgumentList = ( 'yuriy.samorodov@veeam.com' , ( 'K@znachey' | ConvertTo-SecureString -AsPlainText -Force ) ) 
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
    }
} while ( 
    $currentStart -le $EndDate
)