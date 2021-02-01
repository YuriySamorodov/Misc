function GetADUserSubordinatesRecursive {
    param (
        $Identity
    )
    $UserAD = Get-ADUser $Identity -Properties DirectReports
    $DirectReports = $UserAD.DirectReports
    for ( $i = 0 ; $i -lt $DirectReports.Count ; $i++ ) {
        GetADUserSubordinatesRecursive -Identity $DirectReports[$i]  
        if ( ( Get-ADUser -Identity $DirectReports[$i] ).Enabled ) {
            Write-Output $DirectReports[$i]
        }
    }
}