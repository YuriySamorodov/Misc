param (
    $StartDate,
    $EndDate
)


$interval = 15
$ResultSize = 5000
$recordTypes = @(
    'SharePoint',
    'SharepointFileOperation',
    'SharePointSharingOperation'
)

$currentStart = $null
do {
    $jobs = for ($i = 0 ; $i -lt 60) {
        if (
            $currentStart -eq $null
        ) {
            $currentStart = $StartDate
        }
        $JobName = "SPOLogs$($CurrentStart.ToString("yyyyMMddHHmm"))-$($RecordType)"
        Start-Job -Name $JobName -ScriptBlock {   
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
        Remove-PSSession $ExchangeSession
        Start-Sleep -Milliseconds 500
    }
    Start-Sleep -Seconds 60
    $jobs | Wait-Job | Out-Null
    $jobs | Receive-Job
    $jobs | Remove-Job
    $currentStart = $currentStart.AddHours(1)
    Start-Sleep -Milliseconds 500
} 
until ( 
    $currentStart -eq $EndDate 
    )