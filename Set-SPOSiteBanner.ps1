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
