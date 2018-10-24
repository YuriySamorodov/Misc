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
        if ( $i = 0 ) {
            $JobName = "SPOLogs$($EndDate.ToString("yyyyMMddHH"))0$($i)00-$($RecordType)"
        } else { 
            $JobName = "SPOLogs$($EndDate.ToString("yyyyMMddHH"))$($i)00-$($RecordType)"
        }
        Start-Job -Name $JobName -ScriptBlock {   
            param (
                $StartDate,
                $EndDate,
                $RecordTypes,
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
                    RecordType = $recordType
                    ResultSize = $ResultSize
                }
                Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters
            } while ($auditData.Count % 5000 -eq 0 )
        } -ArgumentList $interval,$startDate,$endDate,$recordTypes,$ResultSize
    }
}
