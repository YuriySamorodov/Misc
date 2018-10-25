$jobs = @()
$currentStart = $null
do {
    if (
            $currentStart -eq $null
        ) {
            $currentStart = $StartDate
        }
        $JobName = "SPOLogs$($CurrentStart.ToString("yyyyMMddHHmm"))"
        $jobs += Start-Job -Name $JobName -ScriptBlock {   
        param (
            $JobName
        )
            $JobName 
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
        } -ArgumentList $JobName
        $i = $i + $interval
        Get-PSSession | Remove-PSSession
        Start-Sleep -Milliseconds 500
        
    #Start-Sleep -Seconds 60
    #$jobs = Get-Job
    if ($jobs.Count -eq 12 ) {
        $jobs | Wait-Job | Out-Null
        $results = $jobs | Receive-Job
        $jobs | Remove-Job
        $results | export-csv -NoTypeInformation "$($Jobname).log"
        $currentStart = $currentStart.AddHours(1)
        Start-Sleep -Seconds 60
    } else {
        continue
    }
} 
until ( 
    $currentStart -eq $EndDate 
    )