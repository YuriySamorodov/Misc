function New-SPOnlineSite {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #[Parameter(mandatory=$true)]
        #[ValidateNotNullOrEmpty()]
        #[System.Management.Automation.PSCredential]
        #[System.Management.Automation.Credential()]
        #$Credential = [System.Management.Automation.PSCredential]::Empty,
        [string]$SiteTitle,
        [ValidateSet("Disabled","ExternalUserSharingOnly")]
        [string]$ExternalSharing = 'Disabled',
        [int]$StorageQuota = 5120,
        [int]$WarningQuota = ($StorageQuota * 0.98),
        [string]$Template = "STS#3",
        [array]$Owners,
        [array]$Designers,
        [array]$Members,
        [array]$Contributors,
        [array]$Visitors
    )


    $global:credential = Get-Credential;
    #$global:cred = $global:creds = $global:credentials = $global:credential
    $TenantName = "veeamsoftwarecorp.sharepoint.com"
    $AdminUrl = "https://veeamsoftwarecorp-admin.sharepoint.com/"
    $TenantURL = "https://veeamsoftwarecorp.sharepoint.com"
    $SiteUrl = "$($TenantURL)/sites/$($SiteTitle)"
    $SiteOwner = $global:credential.UserName
    $SiteCollectionAdmins = @("c:0t.c|tenant|1aa07d2c-c093-49b3-b9d7-d4194c915317
    $SiteOwner") -split "`n"
    $SiteCollectionAdmins = $SiteCollectionAdmins.Trim()



    # $PnPOnline = @{
    #     Url = $AdminUrl
    #     TenantAdminUrl = $AdminUrl
    #     Thumbprint = '3bc79c67f5d68abbdae90760c57d4e8cd3b2ea12'
    #     ReturnConnection = $true
    #     ClientId = '15460790-5201-4749-ac72-7812b8d8bffd'
    #     Tenant = 'ba07baab-431b-49ed-add7-cbc3542f5140'
    # }


    # $PnPOnline = @{
    #     TenantAdminUrl = $AdminUrl
    #     Url = $AdminUrl
    #     Credentials = $Credential
    #     SkipTenantAdminCheck = $true
    #     ReturnConnection = $true
    #     #UseWebLogin = $true
    #     #OutVariable = "PnPConnection"
    #}


    # Connect-PnPOnline @PnPOnline | Out-Null
    # #$PnPConnection = Connect-PnPOnline -TenantAdminUrl $AdminUrl -Credentials $creds -SkipTenantAdminCheck -Url $AdminUrl -ReturnConnection
    # $PnPConnection = Get-PnPConnection



    function Connect-PnPSite {
        [CmdletBinding()]
        param (
            $Url
        )

        $Params = [ordered]@{
            #Credential = $Credential
            TenantAdminUrl = $AdminUrl
            Thumbprint = '3bc79c67f5d68abbdae90760c57d4e8cd3b2ea12'
            #eturnConnection = $true
            ClientId = '15460790-5201-4749-ac72-7812b8d8bffd'
            Tenant = 'ba07baab-431b-49ed-add7-cbc3542f5140'
        }
        Connect-PnPOnline @PSBoundParameters @Params
    }

    Connect-PnPSite -Url $AdminUrl
    $PnPConnection = Get-PnPConnection


    $PnPTenantSite = @{
        Title = $SiteTitle
        Url =  $SiteUrl
        Owner = $SiteOwner
        Template = $Template
        TimeZone = "13"
        Connection = $PnPConnection
        Lcid = "1033" #1049 for ru-RU; 1033 for en-US
        StorageQuota = $StorageQuota
        StorageQuotaWarningLevel = $WarningQuota
        OutVariable = "site"
        Wait = $true
    }
    New-PnPTenantSite @PnPTenantSite | Out-Null

    #Comment before pushing to production
    $site = Get-PnPTenantSite $PnPTenantSite.Url
    Write-Information "`n$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) has been created"
    #Break if site has not been created
    if ( -not $site ) {
        Break 
    }

    #Set theme
    $theme = Get-PnPTenantTheme
    Set-PnPWebTheme -Theme $theme -WebUrl $site.Url 
    Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) theme has been changed"

    Disconnect-PnPOnline
    Connect-PnPSite -Url $Site.Url
    $PnPConnection = Get-PnPConnection

    $SetPnPSite = @{
        #Connection = $PnPConnection
        Identity = $Site.Url
        Owners = $SiteCollectionAdmins
        #TimeZone = "13"
        #LocaleId = "1033" #1049 for ru-RU; 1033 for en-US
        StorageMaximumLevel = $StorageQuota
        StorageWarningLevel = $WarningQuota
        DefaultLinkPermission = "None" #Respect the organization default sharing link permission
        DefaultSharingLinkType = "None" #Respect the organization default sharing link type
        DisableSharingForNonOwners = $true
        DisableAppViews = "Disabled" 
        DisableFlows = $true
        #SharingCapability = "Disabled" #Commented to prevent extra alerts generated
        #Wait = $true
    }
    Set-PnPSite @SetPnPSite
    Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) has been updated"

    #Versionning settings
    $LibrarySettings = @{
        Identity = "Documents"
        EnableVersioning = $true
        MinorVersions = 0
        MajorVersions = 20
    }
    Set-PnPList @LibrarySettings | Out-Null
    Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) Versioning have been limited for Documents"

    Disconnect-PnPOnline

    #Announcements list (in case of externally shared site)
    if ($ExternalSharing -ne 'Disabled') {    
        Connect-PnPSite -Url $PnPTenantSite.Url | Out-Null
        $PnPConnection = Get-PnPConnection

        $SetPnPSite = @{
            Connection = $PnPConnection
            Identity = $Site.Url
            Sharing = $ExternalSharing
    }
        Set-PnPSite @SetPnPSite
        Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) has been updated"

        Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) started working on custom list"

        $PnPCustomAction = @{
            ClientSideComponentId = "7ad4348c-1367-461d-a343-842a95c616bb"
            Name = "veeam-spo-announcements-bar"
            Title = "veeam-spo-announcements-bar"
            #Description = "Adds a global header/footer to the site"
            Location = "ClientSideExtension.ApplicationCustomizer"
            ClientSideComponentProperties = "{""siteUrl"":""$($SiteUrl)"", ""listName"" : ""Announcements""}"
            OutVariable = "PnPCustomAction"
        }
        #Add-PnPCustomAction -Name $spfxExtName -Title $spfxExtTitle -Description $spfxExtDescription -Location $spfxExtLocation -
        Add-PnPCustomAction @PnPCustomAction | Out-Null
        Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) Created Custom action"
        
        
        $ListName = 'Announcements'
        
        $NewPnPList = @{
            Title = $ListName
            Template = 'GenericList'
            EnableVersioning = $false
            OnQuickLaunch = $false
        }

       New-PnPList @NewPnPList | Out-Null
        Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) Created a list"
        #$PnPList = Get-PnPList $NewPnPList.Title


       function AddListColumns {
            param (
                [string]$List = $ListName,
                [string]$FieldType,
                [string]$FieldName
            )

            $FieldXML = "<Field 
                        Type='$($FieldType)' 
                        Name='$($FieldName)' 
                        ID='$([GUID]::NewGuid())' 
                        DisplayName='$($fieldName)' 
                        Required ='FALSE' 
                        RichText='TRUE' 
                        RichTextMode='FullHtml' >
                        </Field>"
 
        
            Add-PnPFieldFromXml -List $List -FieldXml $FieldXML | Out-Null

        }

        $FieldNames = @('Announcement','AnnouncementFull','Urgent')
        for ( $f = 0 ; $f -lt $FieldNames.Count ; $f++ ) {
                $FieldName = $FieldNames[$f]
                $FieldType = switch -Regex ($FieldNames[$f]) {
                    'Announcement' { 'Note' }
                    'Urgent' {'Boolean' }
            }
           AddListColumns -FieldName $FieldName -FieldType $fieldType -List $NewPnPList.Title | Out-Null
        }

        Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) created Fields"
         
         #Add Annoucement wording
         $ShortMessage = "Please be advised information stored on this SharePoint site can be <strong>shared with people outside Veeam</strong> whose personal accounts are not controlled by Veeam IT."
         $LongMessage = "Before you upload files containing sensitive business information on this site, keep in mind the following risks of data leak:
                        <ol>
                        <li>The <strong>information can be exposed</strong> to the public Internet unintentionally.</li>
                        <li>Once the information becomes available to people outside Veeam, an <strong>opportunity for data compromise</strong> is provided. Therefore, the information may also become available to unwanted people.</li>
                        </ol>
                        Considering all the menttioned above, please follow these rules:
                        <ol>
                        <li>Be careful when storing business information on this site and make sure it is <strong>NOT</strong> for Veeam internal use only.</li>
                        <li>Keep the file storage updated. If a file does not need to be shared with people outside Veeam any longer, remove it from the site.</li>
                        </ol>"

        $ListItemValues = @{
            Title = 'Announcement'
            Announcement = $ShortMessage ;
            AnnouncementFull = $LongMessage ; 
            Urgent = $true 
        }

        $PnPListItem = @{
            List = 'Announcements'
            Values = $ListItemValues

        }
        Add-PnPListItem @PnPListItem | Out-Null
        Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) added announcement list item"
        #Set-PnPListItemPermission -List $ListName -Identity $PnPListItem -InheritPermissions:$false -SystemUpdate:$true
        #Set-PnPListItemPermission -List $ListName -Identity $PnPListItem -User "Everyone except external users" -AddRole "Read"
        Set-PnPList -Identity $ListName -BreakRoleInheritance -ClearSubscopes | Out-Null
        Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) broke inheritance on $ListName"
        Set-PnPListPermission -Identity $ListName -User "Everyone except external users" -AddRole "Read" | Out-Null
        Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) set $ListName content visible for internal users only"


    }

    Disconnect-PnPOnline
    
    Start-Sleep -Seconds 30

    #SharePoint Groups
    $Groups = @("Designers
    Contributors" ) -split "`n"
    $Groups = $Groups.Trim()


    Connect-PnPSite -Url $PnPTenantSite.Url | Out-Null
    $PnPConnection = Get-PnPConnection 
    # $PnPConnection = Connect-PnPOnline -Credentials $Credential -Url $PnPTenantSite.Url -ReturnConnection
    #Connect-PnPOnline -UseWebLogin -Url $PnPTenantSite.Url -TenantAdminUrl $AdminUrl | Out-Null

    function SetGroupPermissions  {
        param (
            $Name
        )
        $Permissions = switch -Regex ($Name) {
            "Owner" { "Full Control" }
            "Designer" { "Design" }
            "Member" { "Edit" }
            "Contributor" { "Contribute" }
            "Visitor" { "Read" }
        }
        Set-PnPGroupPermissions -Identity $Name -AddRole $Permissions  | Out-Null             
    }



    function NewGroup {
        param (
            [string]$Name,
            [string]$Url
        )
        #$SiteTitle = $PnPTenantSite.Url.Split('/')[-1]
        $Title = "$SiteTitle $Name"
        $Owner = Get-PnPGroup "$SiteTitle Owners"
        $PnPGroup = @{
            #Web = $Url
            Title = $Title
            Owner = $Owner.Title
            AllowMembersEditMembership = $false
            AllowRequestToJoinLeave = $false
            AutoAcceptRequestToJoinLeave = $false
            #OnlyAllowMembersViewMembership = $false
            DisallowMembersViewMembership = $true
            RequestToJoinEmail = $null
        }
        New-PnPGroup @PnPGroup | Out-Null
        $group = Get-PnPGroup $PnPGroup.Title
        SetGroupPermissions -Name $group.Title
    }

    for ( $i = 0 ; $i -lt $Groups.Count ; $i++ ) {
        NewGroup -Name $Groups[$i] -Url $site.Url
    }


    #Add Users to groups
    Connect-AzureAD -Credential $global:credential | out-Null
    #Add Veeam.TeamVeeamCon to Designers group
    $Group = Get-AzureADGroup -SearchString "Veeam.TeamVeeamCom"
    Add-PnPUserToGroup -LoginName "c:0t.c|tenant|$($Group.ObjectId)" -Identity "$($site.Title) Designers" | Out-Null



    function AddSPOSiteGroupMember {
        param (
            [string]$Identity,
            [string]$Group
        )
        $LoginName = Get-AzureADUser -SearchString $Identity
        if ( $null -ne $LoginName ) {
            $LoginName = $LoginName.UserPrincipalName
        } else {
            $LoginName = Get-AzureADGroup -SearchString $Identity
            $LoginName = "c:0t.c|tenant|$($LoginName.ObjectId)"
        }
        $Group = "$SiteTitle $Group"
        Add-PnPUserToGroup -LoginName $LoginName -Identity $Group | Out-Null
    }

    for ($u = 0 ; $u -lt $Owners.Count ; $u++ ) {
        AddSPOSiteGroupMember -Identity $Owners[$u] -Group "Owners"
    }

    for ($u = 0 ; $u -lt $Designers.Count ; $u++ ) {
        . AddSPOSiteGroupMember -Identity $Designers[$u] -Group "Designers"
        Write-Host "$($Designers[$u])"
    }

    for ($u = 0 ; $u -lt $Members.Count ; $u++ ) {
        AddSPOSiteGroupMember -Identity $Members[$u] -Group "Members"
    }

    for ($u = 0 ; $u -lt $Contributor.Count ; $u++ ) {
        AddSPOSiteGroupMember -Identity $Contributor[$u] -Group "Contributors"
    }

    for ($u = 0 ; $u -lt $Visitors.Count ; $u++ ) {
        AddSPOSiteGroupMember -Identity $Visitors[$u] -Group "Visitors"
    }

    
    #Microsoft Graph Way to get groups
    # $MgGraphProps = @{
    #     CertificateThumbprint = '3BC79C67F5D68ABBDAE90760C57D4E8CD3B2EA12'
    #     ClientId = '15460790-5201-4749-ac72-7812b8d8bffd'
    #     TenantId = 'ba07baab-431b-49ed-add7-cbc3542f5140'
    # }
    # Connect-MgGraph @MgGraphProps
    # $group = Get-MgGroup -Filter "StartsWith(DisplayName,'Veeam.TeamVeeamCom')"

    # function AddSPOSiteGroupMember {
    #     param (
    #         [string]$Identity,
    #         [string]$Group
    #     )
        
    #     switch -Regex ($Identity) {
    #         '\w+@w+$' {  $IdProperty ='mail' }
    #         "\s" {  $IdProperty ='DisplayName' }
    #         "w+\.w+$" {  $IdProperty ='mail' }
    #     }

    #     $LoginName = Get-MgUser -Filter "$IdProperty eq '$Identity'"
    #     if ( $null -ne $LoginName ) {
    #         $LoginName = $LoginName.UserPrincipalName
    #     } else {
    #         $LoginName = Get-MgGroup -Filter "$IdProperty eq '$Identity'"
    #         $LoginName = "c:0t.c|tenant|$($LoginName.Id)"
    #     }
    #     $Group = "$SiteTitle $Group"
    #     #Add-PnPUserToGroup -LoginName $LoginName -Identity $Group | Out-Null
    #     Write-Output $LoginName
    # }

Test-Path

    Disconnect-PnPOnline

    Write-Information "$(get-date -Format "yyy-MM-dd HH:mm:ss" ) $($PnPTenantSite.Url) successfully provisioned"


}