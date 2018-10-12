$start = Get-Date ; 
$resultSize = 5000 ;
[datetime]$startDate = '09/12/2018'
[datetime]$endDate = '10/13/2018'
$auditData = @() ; 
$auditData = Search-UnifiedAuditLog -RecordType SharePoint, SharePointFileOperation, SharePointSharingOperation -SessionCommand ReturnLargeSet -EndDate $endDate -StartDate $startDate -SessionId "SPOLogSearch" -ResultSize $resultSize  ;
do { 
Write-Host "$($auditData[-1].ResultIndex)"
$auditData += Search-UnifiedAuditLog -RecordType SharePoint, SharePointFileOperation, SharePointSharingOperation -SessionCommand ReturnLargeSet -EndDate $endDate -StartDate $startDate -SessionId "SPOLogSearch" -ResultSize $resultSize ; 
Start-Sleep -Milliseconds 500 
} 
while ( $auditData.Count % $resultSize -eq 0 ) ; 
$end = Get-Date 
