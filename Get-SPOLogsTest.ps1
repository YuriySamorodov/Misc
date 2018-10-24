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

foreach ( $recordType in $recordTypes) {
    for ($i = 0 ; $i -lt 60) {
        $JobName = "SPOLogs$($EndDate.ToString("yyyyMMddHHmm"))-$($RecordType)"
        Start-Job -Name $JobName -ScriptBlock {   
            param (
                $StartDate,
                $EndDate,
                $RecordType,
                $ResultSize,
                $interval
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
                    RecordType = $recordType
                    ResultSize = $ResultSize
                }
                Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters
            } while ($auditData.Count % $ResultSize -eq 0 )
        } -InitializationScript {
            Import-Module .\New-Office365Session.ps1 ;
            New-Office365Session 'yuriy.samorodov@veeam.com' 'K@znachey'
        } -ArgumentList $startDate,$endDate,$recordType,$ResultSize,$interval
        Get-PSSession | Remove-PSSession
        $i = $i + $interval
    }
}
