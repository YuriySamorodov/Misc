& 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'
Connect-ExchangeServer -auto -ClientApplication:ManagementShell


$Mailboxes = Get-Mailbox -OrganizationalUnit primesports | where { $_.UserPrincipalName -match "mark.emanuel@svlotteries.com|shameaka.cummings@svlotteries.com|romario.bennett@svlotteries.com|jeffrey.parnell@svlotteries.com|Alicia.Swaby@svlotteries.com|sheldon.mignott@svlotteries.com|applications@svlotteries.com|marshalee.menzie@svlotteries.com|kimone.walker@svlotteries.com|InfoExchangeADSyncaccount@svlotteries.com|tajene.williams@svlotteries.com|robert.ebanks@svlotteries.com|mary-ann.meggs@svlotteries.com|stacy-ann.boswell@svlotteries.com" } ;



$ErrorActionPreference ='Stop'

foreach ( $mbx in $Mailboxes3 ) {

    try { 
        $DisableMailbox = @{
            Identity = $mbx.Identity
            Confirm = $false
        }
        DisableMailbox @DisableMailbox
        
        $UpdateStoreMailboxState = @{
            Database = $mbx.Database
            Identity = $mbx.ExchangeGuid
        }
        Update-StoreMailboxState @UpdateStoreMailboxState
        Start-Sleep -Seconds 5
    
    }

    catch {}

    finally {

        $EnableMailbox = @{
            Identity = $mbx.UserPrincipalName
            Database = $mbx.Database
            AddressBookPolicy = $mbx.AddressBookPolicy
            PrimarySmtpAddress = $mbx.PrimarySmtpAddress
            RetentionPolicy = $mbx.RetentionPolicy
            #BypassModerationCheck = $true
            Confirm = $false
            Force = $true
        }
        Enable-Mailbox @EnableMailbox

        Start-Sleep -Seconds 20

foreach ( $mbx in $Mailboxes4 ) {

        $targetAddress = [string]::Concat(
            ( $mbx.Name.Substring(0, $mbx.Name.Indexof( '@') + 1 ) ),
            'PrimeSports-CTL.serverdata.net'.ToString().Trim()
       )

        $SetADUser = @{
            Identity = $mbx.Distinguishedname
            Replace = @{ targetAddress = $targetAddress }
        }
  
        Set-ADUser @SetADUser
}
    }

}
    
foreach ( $mbx in $Mailboxes3 ) {

    $NewMailboxRestoreRequestParameters = @{
        Name = $mbx.UserPrincipalName
        BatchName = '2764970'
        TargetMailbox = $mbx.UserPrincipalName
        SourceStoreMailbox = $mbx.ExchangeGuid
        SourceDatabase = $mbx.Database
        AllowLegacyDNMismatch = $true
    }
    New-MailboxRestoreRequest @NewMailboxRestoreRequestParameters

}

