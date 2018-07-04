for ( $i = 0 ; $i -lt $OneDriveSites.Count ; $i++ ) {
Write-Progress -Activity "Collecting data..." -Status $OneDriveSites[$i].Title -PercentComplete ( $i / $OneDriveSites.Count * 100 ) -CurrentOperation  "$( $i / $( $OneDriveSites.Count ) * 100 )%"
$admins = Get-SPOUser -Site $OneDriveSites[$i].Url
$admins = $admins | where { $_.isSiteAdmin }
$admins = $admins | where { $_.LoginName -NotMatch $OneDriveSites[$i].Owner }
$admins = $admins | select -ExpandProperty LoginName
$props = @{
'SiteURL' = $OneDriveSites[$i].Url
'SiteTitle' = $OneDriveSites[$i].Title
'SiteOwner' = $OneDriveSites[$i].Owner
'Admins' = $admins
'Status' = $OneDriveSites[$i].Status
'LockState' = $OneDriveSites[$i].LockState
}
New-Object psobject -Property $props
}
