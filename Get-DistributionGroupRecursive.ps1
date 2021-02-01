function Get-DistributionGroupRecursive {
    param (
        [string]$Identity
    )
    #$ErrorActionPreference = 'Stop'
    $members = Get-DistributionGroupMember -Identity $Identity
    for ( $i = 0 ; $i -lt $members.Count ; $i++ ) {
        if ( $members[$i].RecipientType -match 'group' ) {
            Get-DistributionGroupRecursive -Identity $members[$i].Name
        }
        if ( $members[$i].RecipientType -match 'mailbox') {
            $member = Get-ADUser -LDAPFilter "(&(Name=$($members[$i].Name))(!(UserAccountControl:1.2.840.113556.1.4.803:=2)))"
            $objProps = [ordered]@{}
            for ( $p = 0 ; $p -lt $member.PropertyCount ; $p++){
                $property = ([array]$member.PropertyNames)[$p]
                $objProps.Add(
                    $property,
                    $member.$property
                )
            }
            $objProps.Add('GroupName', $Identity)
            New-Object PSCustomObject -Property $objProps
        }
    }
}
