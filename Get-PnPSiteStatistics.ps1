$ScriptStart = Get-Date

function GetADUserSubordinatesRecursive {
    param (
        $Identity
    )
    
    $UserAD = Get-ADUser $Identity -Properties DirectReports
    $DirectReports = $UserAD.DirectReports
    for ( $i = 0 ; $i -lt $DirectReports.Count ; $i++ ) {
        GetADUserSubordinatesRecursive -Identity $DirectReports[$i]
        $User = Get-ADUser -Identity $DirectReports[$i]  
        if ( $user.Enabled ) {
            Write-Output $User
        }
    }
}


$CISUsers = GetADUserManagerRecursive -Identity "max"  #Maxim Ivanov Subordinates

#Export data from Kiwi
Set-ConfluenceInfo -baseUri 'https://kiwi.veeam.local' -Credential (Get-Credential)
$page = Get-ConfluencePage -PageID 19727052
$body = $page.body
$html = New-Object -ComObject "HTMLFile"
#$html.IHTMLDocument2_write($body)
$src = [System.Text.Encoding]::Unicode.GetBytes($body)
$html.write($src)
$headers = $html.all.tags("th") | %{ $_.InnerText.Trim() -replace "`r`n", " " }
$values = $html.all.tags("td") | %{ $_.OuterText }
#$values = $values | %{ $_ -replace "^$", "N/A" }

$KiwiSites = for ( $i = 0 ; $i -lt $values.Count ; $i = $i+$headers.Count ) {
    $properties = [ordered]@{}
    for ( $h = 0 ; $h -lt $headers.Count ; $h++) {
        $properties += @{
            $headers[$h] = $values[$i+$h]
        }
    }
    $obj = New-object psobject -property $properties
    Write-Output $obj
}


Import-Module PnPSharePointOnline


[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls13;
$AdminUrl = 'https://veeamsoftwarecorp-admin.sharepoint.com'
$SystemItemCount = 271 #( Get-PnPList ).ItemCount | Measure -Sum
function Connect-PnPSite {
    [CmdletBinding()]
    param (
        $Url
    )

    if ( Get-PnPConnection ) {
        Disconnect-PnPOnline
    }   
    $Params = [ordered]@{
        TenantAdminUrl = $AdminUrl
        Thumbprint = '3bc79c67f5d68abbdae90760c57d4e8cd3b2ea12'
        ReturnConnection = $true
        ClientId = '15460790-5201-4749-ac72-7812b8d8bffd'
        Tenant = 'ba07baab-431b-49ed-add7-cbc3542f5140'
    }
    Connect-PnPOnline @PSBoundParameters @Params
    $PnPConnection = Get-PnPConnection
}

$PnPConnection = Connect-PnPSite -Url $AdminUrl 


$PnPTenantSites = Get-PnPTenantSite -Connection $PnPConnection
$PnPTenantSitesExternal = $PnPTenantSites | where { $_.SharingCapability -ne 'Disabled'}

for ( $i = 0 ; $i -lt $pnpTest[0].Count ; $i++ ) {
    $Connection = Connect-PnPSite -Url $pnpTest[$i].Url 
    #$Connection.Url
    $Owners = Get-PnPGroup -AssociatedOwnerGroup -Connection $Connection | Get-PnPGroupMembers

    for ( $o = 0 ; $o -lt $Owners.Count ; $o++ ) {
        if ($Owners[$o].Email -in $CISUsers.Mail -or $Owners[$o].Email -in $CISUsers.UserPrincipalName ) {
            $pnpTest[$i]
            break
        }  
    }
}


$CISTenantSites = Get-PnPTenantSite -Filter "URL -like ""*cis*"""
$CISTenantSites = $CISTenantSites | where { $_.SharingCapability -ne 'Disabled' -and $_.Title -notmatch "Cisco" }



#Enumerate through sites collecting details
$Report = foreach ( $s in $CISTenantSites ) {
    Connect-PnPSite -Url $s.Url | Out-Null
    $connection = Get-PnPConnection

    #Collect site details
    $site = Get-PnPSite -Connection $connection -Includes Owner, RootWeb, Usage
    $ItemsSizeTotal = [math]::Round($site.Usage.Storage/1MB, 2)
    $siteStorageQuota = [math]::Round( ( $site.Usage.Storage / $site.Usage.StoragePercentageUsed ) /1MB , 2 )
    
    #Enumerate files
    $SiteLists = Get-PnPList | where { $_.BaseTemplate -eq 101 -and $_.Hidden -eq $false }
    $items = foreach ( $list in $siteLists ) {
        Get-PnPListItem -List $list -PageSize 500
        # Get-PnPListItem -List $list -Query "<View Scope='RecursiveAll'><OrderBy Override='TRUE' Ascending='TRUE'><FieldRef Name='ID'/></OrderBy></View>"
    }
    $files = $items | where { $_.FileSystemObjectType -eq 'File' }
    $filesWord = @()
    $filesWord += $files | where { $_.FieldValues['File_x0020_Type'] -match "doc|docx" }
    $filesExcel = @()
    $filesExcel += $files | where { $_.FieldValues['File_x0020_Type'] -match "xls|xlsx" }
    $filesOther = @()
    $filesOther += $files | where { $_.FieldValues['File_x0020_Type'] -notmatch "xls|xlsx|doc|docx" }

    #users

    #Try to get owner from Kiwi
    $KiwiSite = $KiwiSites | where { $_.'Site Name' -eq $site.RootWeb.Title }
    $Owner = Get-PnPUser | where { $_.Title -eq $KiwiSite.Owner }
    $Owner = $Owner.Email

    if ( $Owner -eq $null ) {
        $Owner = Get-PnPGroup -AssociatedOwnerGroup | Get-PnPGroupMembers
        $Owner = $Owner | where { $_.LoginName -match "i:0#.f" }
        $Owner = $Owner | where { $_.Email -match "@" }
        $Owner = $Owner | where { $_.Email -notmatch "^cadm-" }
        $Owner = $Owner | sort id
        $Owner = $Owner | select -First 3
        $Owner = $Owner | % { Get-PnPUserProfileProperty -Account $_.LoginName -Connection $PnPConnection }
        $Owner = $Owner | where { $_.ExtendedManagers -notcontains "i:0#.f|membership|ialexandrov@veeam.com" }
        $Owner = $Owner | select -First 1
        $Owner = $Owner | select -ExpandProperty Email
    
        if ( $Owner -eq $null ) {
            Write-Host "$($site.RootWeb.Title) does not have owners. Checking O365 Groups"
            $Owner = Get-PnPMicrosoft365GroupOwners -Identity $site.RootWeb.Title
            $Owner = $Owner.UserPrincipalName -join ';'
        }
    }

    #prepare report
    $Properties = [ordered]@{
        'Title' = $site.RootWeb.Title
        'Url' = $site.RootWeb.Url
        'Owner' = $Owner
        'Created' = $site.RootWeb.Created
        'Last Activity Date' = $site.RootWeb.LastItemModifiedDate
        'Site Storage Quota' = $siteStorageQuota
        'Size of Files' = $ItemsSizeTotal
        'Count of Doc' = $filesWord.Count
        'Count of Excel' = $filesExcel.Count
        'Count of Other' = $filesOther.Count
    }
    $obj = New-Object psobject -Property $Properties
    $obj
}

#region CSS
$header = @"
<style>
    table, th, td, tbody {
        font-family: sans-serif;
        border-collapse: collapse;
        border: 1px solid black;
        font-size: 14px;
        padding: 0px 10px;
        vertical-align: middle;
        width: 100%
    }
    th {
        background: #328208;
        color: #fff;
        padding: 10px 15px;
        font-weight: bold;
        font-size: 16px;
    }
    
    tbody tr:nth-child(odd) {
        background: #b9f98e;
    }
</style>
"@
#endregion


$ScriptEnd = Get-Date
$ScriptRunTime = $ScriptEnd - $ScriptStart
$PostContent = "Script completed in: $($ScriptRunTime.Hours) hour(s) $($ScriptRunTime.Minutes) minute(s) $($ScriptRunTime.Seconds) second(s)"

$HTMLReport = $Report | ConvertTo-Html -Head $header -Title "CIS Externally Shared Sites" -PostContent $PostContent


# Send Report
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true } ; 

$RecipientsTo = @('max@veeam.com
valentin.grebenev@veeam.com')
$Recipients = $Recipients -split "`n"

$RecipientsCC = @('alexey.soloviev@veeam.com
leonid.kapelson@veeam.com
yuriy.samorodov@veeam.com')
$Recipients = $Recipients -split "`n"


$MessageProps = @{
    Body = $( $HTMLReport -as [string] )
    BodyAsHtml = $true
    From = $Sender
    To = $RecipientsTo
    CC = $RecipientsCC
    SmtpServer =  'spbmbx01.amust.local'
    Subject =  "CIS External Sites"
    Port =  '25'
}
Send-MailMessage @MessageProps