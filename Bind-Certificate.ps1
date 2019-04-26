function Bind-Certificate {
        param (
            $ComputerName,
            $SiteName,
            $Thumbprint
        )
    $ScriptBlock = {
            $cert = $null
            $iisSite = $null
            $binding = $null
            $hostname = $null
            $issuer = $null 

            $iisSite = $SiteName
            #$hostname = 'eac.v-index.com'
            $issuer = 'SPBECA'
            $Thumbpint = $Thumbpint
            $ErrorActionPreference = 'Stop'

            $cert = Get-ChildItem Cert:\LocalMachine\My
            $cert = $cert | Where-Object { $_.Subject -match $hostname }
            $cert = $cert | Where-Object { $_.Issuer -match $issuer }
            $cert = $cert | Sort-Object -Property NotAfter -Descending
            $cert = $cert[0]  
            $binding = Get-WebBinding -Name $iisSite -Port 443
            
            try { 
                $binding.AddSslCertificate($cert.GetCertHashString(),'my')
                Write-Output "$($env:COMPUTERNAME): $iissite new cert: $($Cert.Issuer), $($Cert.NotAfter)"
            }
            catch { Write-Warning "$($env:COMPUTERNAME): $iisSite not found" }
    }

    foreach ( $server in $servers ) {
        Invoke-Command -ComputerName $server.Name -ScriptBlock $ScriptBlock
    }
}
