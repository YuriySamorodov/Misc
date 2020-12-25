function New-Group {
    param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$SiteName,
        [string[]]$GroupNames = @(
            'Contributors'
            'Members'
            'Owners'
            'Visitors'
            'Designers'
        ),
        [parameter(Mandatory=$true,Position=2)]
        [string]$Owner,
        [string]$GroupCategory = 'Security',
        [string]$GroupScope = 'DomainLocal',
        [string]$OrganizationalUnit = 'Sharepoint'
    )

    $GetOrganizationalUnitParams = @{
        Filter =  "Name -like ""*$OrganizationalUnit*"""
    }
    $OrganizationalUnit = Get-ADOrganizationalUnit @GetOrganizationalUnitParams
    # $OrganizationalUnit = Get-ADOrganizationalUnit -Filter "Name -like ""*$OrganizationalUnit*"""

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
            Path = $OrganizationalUnit
            Description = $description
        }
        New-ADGroup @NewGroupParams
    }
}
