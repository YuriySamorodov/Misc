

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
                $СurrentStart,
                $CurrentEnd,
                $interval,
                $ResultSize
                
            )
            $auditData = @()
            $SessionId = New-Guid
            do {
                $auditData += SearchUnifiedAuditLog
            } while ( $auditData.Count % $ResultSize -eq 0 )
        } -InitializationScript {
            
            function Set-O365Credentials {

                $SecurePasswordParameters = [psobject] @{
                    String = $Pass
                    AsPlainText = $true
                    Force = $true
                }
                $SecurePassword = ConvertTo-SecureString @SecurePasswordParameters

                $AdminCredentialParameters = [psobject] @{
                    TypeName = 'System.Management.Automation.PSCredential'
                    ArgumentList = ( $UserName , $SecurePassword ) 
                }
                $script:AdminCredential =  New-Object @AdminCredentialParameters
            }

            Set-O365Credentials

            function Connect-Exchange {

                $ExchangeSessionParameters = [psobject] @{
                    ConnectionURI = $ConnectionURI
                    ConfigurationName = 'Microsoft.Exchange'
                    Authentication = 'Basic'
                    AllowRedirection = $true    
                    Credential = $AdminCredential
                    AllowClobber = $true
            
                }
                $ExchangeSession = New-PSSession @ExchangeSessionParameters
                
                $ImportSessionParameters =  @{
                    Name = $ExchangeSession
                    DisableNameChecking = $true
                    CommandName = @(
                        'Search-UnifiedAuditLog'
                        'Get-MessageTrace'
                        'Get-MessageTraceDetail'
                        'Get-MessageTrackingReport'
                        'Get-Mailbox'
                        )
                    AllowClobber = $true

                }
                Import-PSSession @$ImportSessionParameters  | Out-Null  
            }
           
           Connect-Exchange
           
           function SearchUnifiedAuditLog {
    
            $SearchUnifiedAuditLogParameters = @{
                SessionCommand = 'ReturnLargeSet'
                SessionId = New-Guid
                StartDate = $CurrentStart
                EndDate = $CurrentEnd
                FreeText = "sharepoint\.com"
                ResultSize = 5000
            }         
            Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters
        }
         
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