function Get_ConfluenceTable {
    param (
        [pscredential]$Credential,
        [string]$ConfluenceUri,
        [int]$PageID
    )
    Import-Module ConfluencePS
    Set-ConfluenceInfo -baseUri $ConfluenceUri -Credential $Credential
    $Page = get-ConfluencePage -PageId $PageID
    $body = $page.body
    $html = New-Object -ComObject "HTMLFile"
    
    if ( $PSVersionTable.PSVersion -lt "7.0.0" ) {
        #PowerShell 5 approach
        $html.IHTMLDocument2_write($body)  
    } else {
        #PowerShell 7 approach
        $src = [System.Text.Encoding]::Unicode.GetBytes($body)
        $html.write($src)
    }

    $headers = $html.all.tags("th") | %{ $_.InnerText.Trim() -replace "`r`n", " " }
    $values = $html.all.tags("td") | %{ $_.OuterText }
    #$values = $values | %{ $_ -replace "^$", "N/A" }
    
    for ( $i = 0 ; $i -lt $values.Count ; $i = $i+$headers.Count ) {
        $properties = [ordered]@{}
        for ( $h = 0 ; $h -lt $headers.Count ; $h++) {
            $properties += @{
                $headers[$h] = $values[$i+$h]
            }
        }
        $obj = New-object psobject -property $properties
        Write-Output $obj
    }
    
}