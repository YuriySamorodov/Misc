[System.Collections.ArrayList]$msolUsers = Get-MsolUser | sort DisplayName, isLicensed

for ( $i = 0 ; $i -lt $msolUsers.Count ; $i++ ) {
    while ( ( $msolUsers[$i].Displayname -eq $msolUsers[$i-1].Displayname ) -or ( $msolUsers[$i].Displayname -eq $msolUsers[$i+1].Displayname ) -or ( $msolUsers[-1].DisplayName -eq $msolUsers[$i-2].DisplayName ) ) {
        if ( $msolUsers[$i].isLicensed -eq $false ) {
            $msolusers[$i-1].ProxyAddresses.Add("smtp:$($msolUsers[$i].UserPrincipalname)")
            $msolUsers.RemoveAt($i)
            Write-Output "Removing $( $msolUsers[$i].DisplayName )"
        }
        elseif ( $msolUsers[$i-1].isLicensed -eq $false ) {
            $msolusers[$i].ProxyAddresses.Add("smtp:$($msolUsers[$i-1].UserPrincipalname)")
            $msolUsers.RemoveAt($i-1)
            Write-Output "Removing $( $msolUsers[$i].DisplayName )"
        }
        $i++
    }
}
