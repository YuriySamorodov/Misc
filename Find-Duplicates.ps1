$msolUsers = Get-MsolUser | sort DisplayName, isLicensed

for ( $i = 1 ; $i -lt $msolUsers.Count ; $i++ ) {
    while ( $msolUsers[$i].Displayname -eq $msolUsers[$i-1].Displayname  ) {
        if ( $msolUsers[$i].isLicensed -eq $false ) {
            $msolusers[$i-1].ProxyAddresses += $msolUsers[$i].UserPrincipalname
        }
        elseif ( $msolUsers[$i-1].isLicensed -eq $false ) {
            $msolusers[$i].ProxyAddresses += $msolUsers[$i-1].UserPrincipalname
        }
        $i++
    }
}
