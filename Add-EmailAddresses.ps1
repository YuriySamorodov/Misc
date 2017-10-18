 foreach ( $i in $csv ) { 
     [string[]]$ProxyAddresses = $i.ProxyAddresses.Split(" ") | where { $_ -notmatch "onmicrosoft" } ; 
     $UserPricnipalName = $i.UserPrincipalName ; 
     $ADUser = Get-ADUser -Filter "UserPrincipalName -eq `"$UserPricnipalName`""  ; 
     Set-ADUser -Identity $ADUser.DistinguishedName -Add @{ Proxyaddresses = $ProxyAddresses } 
}
