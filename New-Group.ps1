function New-Group {
    param (
        [string]$SiteName,
        [string[]]$GroupNames,
        [string]$Owner,
        [string]$GroupCategory = 'Security',
        [string]$GroupScope = 'DomainLocal',
        [string]$OrganizationalUnit = 'Sharepoint'
    )

    $OrganizationalUnit = Get-ADOrganizationalUnit -Filter "Name -like ""*$OrganizationalUnit*"""

    for ( $i = 0 ; $i -lt $GroupNames.Count ; $i++ ) {

        $SCL = switch ($GroupNames[$i]) {
            Owners {'Full'}
            Contributors {'Contribute'}
            Designers {'Design'}
            Members {'Edit'}
            Visitors { 'Read-Only' }
        }

        $description = "$SCL access to TVC - $SiteName site. Owner - $Owner"

        $NewGroupParams = @{
            Name = "DSG.TVC.$SiteName.$($GroupNames[$i])"
            GroupCategory = $GroupCategory
            GroupScope = $GroupScope
            Path = "$($OrganizationalUnit.DistinguishedName)"
            Description = $description
        }
        New-ADGroup @NewGroupParams
    }
}
