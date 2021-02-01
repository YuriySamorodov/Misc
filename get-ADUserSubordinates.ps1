function GetADUserDirectReports {
    param (
        $Identity
    )
    $user = Get-ADUser $Identity -Properties DirectReports
    #Write-Output $user.DirectReports
    for ( $i = 0 ; $i -lt $user.DirectReports.Count ; $i++ ){
        Write-Output $user.DirectReports[$i]
        GetADUserDirectReports $user.DirectReports[$i]
    }
}