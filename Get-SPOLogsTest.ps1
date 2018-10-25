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
$jobs = foreach ( $recordType in $recordTypes) {
    for ($i = 0 ; $i -lt 60) {
        $JobName = "SPOLogs$($EndDate.ToString("yyyyMMddHHmm"))"
        $jobs = @()
do  {
    for ($i = 0 ; $i -lt 60) {
        $JobName = "SPOLogs_$($EndDate.ToString("yyyyMMddHHmm"))"
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

