function Get-MsolUserLicensePlan {
 
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$UserPrincipalName,
        [string[]]$LicenseName,
        [string]$LogPath
    )

    $user = Get-MsolUser -SearchString $UserPrincipalName
    [array]$Licenses = $user.Licenses
    [array]$License = $Licenses | where { $_.AccountSkuId -match "Enterprise"}
    $License.ServiceStatus
}
