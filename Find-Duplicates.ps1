[System.Collections.ArrayList]$msolUsers = Get-MsolUser | sort DisplayName, isLicensed
$dupUsers = @()
for ( $i = 0 ; $i -lt $msolUsers.Count ; $i++ ) {
    while ( ( $msolUsers[$i].Displayname -eq $msolUsers[$i+1].Displayname ) ) {
        if ( $msolUsers[$i].isLicensed -eq $false ) {
            $msolusers[$i+1].ProxyAddresses.Add("smtp:$($msolUsers[$i].UserPrincipalname)")
            $dupUsers += $msolUsers[$i]
            $msolUsers.RemoveAt($i)
            $i--
        }
        elseif ( $msolUsers[$i+1].isLicensed -eq $false ) {
            $msolusers[$i].ProxyAddresses.Add("smtp:$($msolUsers[$i+1].UserPrincipalname)")
            $dupUsers += $msolUsers[$i+1]
            $msolUsers.RemoveAt($i+1)
            $i--
        }
        $i++
    }
}
