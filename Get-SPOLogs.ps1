$start = Get-Date ;
$searchGuid = New-Guid
$resultSize = 5000
[datetime]$startDate = '10/09/2018'
[datetime]$endDate = '10/13/2018'
$auditData = @() ;
function SearchUnifiedAuditLog () {
    param (
        [parameter(Mandatory=$true, Position = 1)]
        [guid]$searchGuid,
        [parameter(Mandatory=$true, Position = 2)]
        [datetime]$startDate,
        [parameter(Mandatory=$true, Position = 3)]
        [datetime]$endDate,
        [parameter(Mandatory=$true, Position = 4)]
        [int]$resultSize,
        [parameter(Mandatory=$false, Position = 5)]
        [int]$Timeout
    )
    
    $SearchUnifiedAuditLogParameters = @{
        SessionCommand = 'ReturnLargeSet'
        SessionId = $searchGuid
        StartDate = $startDate
        EndDate = $endDate
        ResultSize = $resultSize
    }
    Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters ;
}

$auditData += SearchUnifiedAuditLog $searchGuid $startDate $endDate $resultSize
Start-Sleep -Milliseconds 500

do {
Write-Host "$($auditData[-1].ResultIndex)"
$auditData += SearchUnifiedAuditLog $searchGuid $startDate $endDate $resultSize
Start-Sleep -Milliseconds 500
}
while ( $auditData.Count % $resultSize -eq 0 ) ;
$end = Get-Date
