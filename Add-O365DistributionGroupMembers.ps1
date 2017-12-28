function Add-O365DistributionGroupMembers {
    param (
        [parameter(Mandatory = $true, Position=1)]
        [string]$Identity = '',
        [parameter(Mandatory = $true, Position=2)]
        [string[]]$Members =  ''
    )

    BEGIN {
    }

    PROCESS {
        for ( $i = 0 ; $i -lt $Members.Count ; $i++ ) {
            $AddDistributionGroupMember = @{
                Identity = $Identity
                Member = $Members[$i]
                BypassSecurityGroupManagerCheck = $true
                Confirm = $false
            }
            Add-DistributionGroupMember @AddDistributionGroupMember
        }
    }

    END {
    }
}
