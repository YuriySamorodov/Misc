function Get-TVCPermission () {
    param (
        [string]$Group
    )
    foreach ( $group in $groups ) { 
        $members = Get-ADGroupMember $group
        foreach ( $member in $members ) {
            $adObject = Get-ADObject $member -Properties mail
            $Properties = [ordered]@{
                Name = $adObject.Name
                Mail = $adObject.mail
                Permission = $group.Name.split('.')[-1]
            }
            New-Object psobject -Property $Properties
        }
    }
}