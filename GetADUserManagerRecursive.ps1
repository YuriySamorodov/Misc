function GetADUserManagerRecursive {
    param (
        $Identity
    )
    $UserAD = Get-ADUser $Identity -Properties Manager
    $DirectManager = $UserAD.Manager
    $DirectManager = Get-ADUser -Identity $DirectManager -Properties Manager
    Write-Output $DirectManager.DistinguishedName
    if ( $DirectManager.Manager -ne $UserAD.DistinguishedName ) {
        GetADUserManagerRecursive -Identity $DirectManager
    }
}