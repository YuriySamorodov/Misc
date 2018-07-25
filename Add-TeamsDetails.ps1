  function Get-TeamsDetails  {
    param (
        [Object]$Group,
        [bool]$TeamsEnabled
    )
    $AddMemberProps = @{
        InputObject = $Group
        MemberType = 'NoteProperty'
        Name = 'TeamsEnabled'
        Value = $TeamsEnabled
        Force = $true
    }
    Add-Member @AddMemberProps
}
