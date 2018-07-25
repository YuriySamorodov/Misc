function Get-TeamsDetails  {
    param (
        [Object]$Group,
        [bool]$TeamsEnabled
    )
    $NewObjectParams = @{
        GroupName = $Group.DisplayName
        GroupEmailAddress = $Group.PrimarySmtpAddress
        Manager = $Group.ManagedBy
        GroupId = $Group.ExternalDirectoryObjectId
        TeamsEnabled = $TeamsEnabled
    }
    New-Object -Property $NewObjectParams -TypeName PSCustomObject

}


foreach ($o365group in $o365groups) {
    try {
        $teamschannels = Get-TeamChannel -GroupId $o365group.ExternalDirectoryObjectId
        Get-TeamsDetails -Group $o365group -TeamsEnabled $true
    } catch {
        $ErrorCode = $_.Exception.ErrorCode
        switch ($ErrorCode) {
            "404" {
                Get-TeamsDetails -Group $o365group -TeamsEnabled $false
            }
            "403" {
                Get-TeamsDetails -Group $o365group -TeamsEnabled $true
            }
            default { Write-Error ("Unknown ErrorCode trying to 'Get-TeamChannel -GroupId {0}' :: {1}" -f $o365group, $ErrorCode)
            }
        }
    }
}
