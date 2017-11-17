$unverifiedDomains = Get-MsolDomain -Status Unv 
for ( $i = 0 ; $i -lt $unverifiedDomains.Count ; $i++ ) {
    $VerificationDNS = Get-MsolDomainVerificationDns -DomainName $unverifiedDomains[$i].name 
    
    $VerificationDNSProperties = @(
        @{
        Name = 'Domain'
        Expression = { $VerificationDNS.Label.Substring( $VerificationDNS.Label.IndexOf('.') + 1 ) }
        }

        @{
        Name  = 'TXTRecord'
        Expression = { $VerificationDNS.Label.Substring( 0 , $VerificationDNS.Label.IndexOf('.') ) }
        }
    )


    
    $VerificationDNSParameters = @{
        InputObject = $VerificationDNS
        Property = $VerificationDNSProperties
    }
    
    Select-Object @VerificationDNSParameters
}
