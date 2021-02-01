$users = Get-MsolUser -EnabledFilter EnabledOnly -All
$users = $users | Where-Object { $_.Licenses.AccountSkuId -contains "VeeamSoftwareCorp:MCOMEETADV" }
$users = $users | Sort-Object userprincipalname

$license = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -eq "VeeamSoftwareCorp:MCOPSTNC" } ;

foreach ( $user in $users ) { 
    if ( $user.Licenses.AccountSkuId -notcontains "$($license.AccountSkuId)" ) {
        Set-MsolUserLicense -ObjectId $user.ObjectId -AddLicenses $license.AccountSkuId ;
        Write-Host "$($user.UserPrincipalName) has been assigned with Communication Credits assigned" -ForegroundColor Green
    }
    else { Write-Host "$($user.UserPrincipalName) has Communication Credits assigned - no action taken" -ForegroundColor Yellow }
}