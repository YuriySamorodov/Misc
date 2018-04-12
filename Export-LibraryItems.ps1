Add-PSSnapin * ; 

$web = Get-SPWeb http://spb.amust.local/hr/russia/
$items = $list = $web.Lists['library'].Items.GetDataTable() 
$properties = @(
    @{ n = 'ID' ; e = { $_.ID } }
    @{ n = 'Author' ; e = { $_.Author0 } }
    @{ n = 'Category' ; e = { $_.Category } }
    @{ n = 'Description' ; e = { $_.Short_x0020_Description.ToString() -replace "<.+?>|`n|\&quot\;|\&\#160|\&\#58", ' '  } }
    @{ n = 'Status' ; e = { $_.StatusNew } }
    @{ n = 'Holder' ; e = { $_.Holder } }
    @{ n = 'DateFrom' ; e = { $_.Date_x0020_From } }
    @{ n = 'DateTo' ; e = { $_.Date_x0020_To_x0020_Auto } }
    @{ n = 'TakenForDays' ; e = { $_.PeriodInDays } }
    @{ n = 'AdditionInfo' ; e = { $_.Additional_x0020_Info } }
    )

$objects = $items | Select-Object -Property $properties

$objects | Export-Csv -Path .\Books.csv -NoTypeInformation -Encoding UTF8
