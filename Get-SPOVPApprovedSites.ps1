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


foreach ($site in $Externalsites ) {
    $userAD = $null
    $user = $site.Owner
    Write-Output $user
    $userAD = Get-ADUser -Filter "DisplayName -eq ""$user""" -Properties manager -ErrorAction 0
    if ( $userAD -ne $null -and $userAD.Enabled -eq $true ) {
        $managers = GetADUserManagerRecursive -Identity $userAD.DistinguishedName
    }
    if ( $managers -match "maxim ivanov" ) {
        $site.'Site Url'
    }
}
