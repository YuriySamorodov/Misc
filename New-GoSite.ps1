#New-SPSite
function  New-GoSite () {
    param (
        [string]$Title,
        [string]$URL,
        [string]$Owner,
        [int]$Ticket,
        [string]$Description
    )

    $relativeUrl = $url.Split('/')[-1]
    $absoluteUrl = "https://team.veeam.com/go/$relativeUrl"
    $ownerObject = Get-ADObject -Filter { DisplayName -eq $Owner }
    $secondaryOwner = whoami /upn
    $description = "EPPM team site.`nTicket: $ticket`nOwner:$owner"

    $NewSPSiteParams = @{
        URL = $absoluteUrl
        Name = $title
        OwnerAlias = $ownerObject.Name
        SecondaryOwnerAlias = ( whoami /upn )
        Description = $description
    }
    
    $script:site = New-SPSite @NewSPSiteParams
}

function Set-SiteTheme () {
    param (
        [string]$Identity,
        [string]$ThemeName
    )
    $web = Get-SPWeb $site.URL
    $themes = $site.GetCatalog('Design')
    $theme = $themes.Items | Where-Object { $_.Name -eq $ThemeName }
    $web.ApplyTheme( $theme["ThemeUrl"].Split(',')[1].Trim(),$null,$null,$true )
    $web.Update()
    $web.Dispose()
}

function Enable-CustomFeatures () {
    param (
        [string]$URL
    )
    $spFeaturesAll = Get-SPFeature -CompatibilityLevel 15
    $spFeatures = $spFeaturesAll | Where-Object { $_.DisplayName -match "^PublishingSite|Branding_.+?e[ns]" }
    $spFeatures = $spFeatures | Sort-Object -Descending
    $PublishingWeb = $spFeaturesAll | Where-Object { $_.DisplayName -eq 'PublishingWeb' }
    $spFeatures += $PublishingWeb

    foreach ( $spfeature in $spFeatures ) { 
        $EnableSPFeature = @{
            Identity = $spFeature
            URL = $URL
            Force = $true
        }
        Enable-SPFeature @EnableSPFeature
    }   

}

function Set-MasterPage () {
    param (
        [string]$MasterPageName,
        [string]$Url
    )
    $web = Get-SPWeb $Url
    $MasterPages = $Web.GetCatalog('masterpage').Items
    $MasterPage = $MasterPages | Where-Object { $_.Name -eq $MasterPageName }
    $web.MasterUrl = $web.ServerRelativeUrl + '/' + $masterPage.Url
    $web.CustomMasterUrl = $web.ServerRelativeUrl + '/' + $masterPage.Url
    $web.Update()
}

function Set-Permissions () {
    
    set-spsite -Identity $site -SecondaryOwnerAlias ( get-adgroup DSG.TVC.Developers ).name
}
