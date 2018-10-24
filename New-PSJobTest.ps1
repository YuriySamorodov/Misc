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
           $JobName 
        } -InitializationScript {
            Import-Module .\New-Office365Session.ps1 ;
            New-Office365Session 'yuriy.samorodov@veeam.com' 'K@znachey'
        } -ArgumentList $interval,$startDate,$endDate,$recordTypes,$ResultSize
        $i = $i + 15
        Get-PSSession | Remove-PSSession
    }
}
