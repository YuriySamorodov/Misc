$file = 'D:\Users\ysamorodov\OneDrive\Downloads\57079+SSPC+ImapTasks.csv' ;
$TempFilePath = $HOME
$csv = import-csv $file
$csv2 = $csv | ConvertTo-Csv -NoTypeInformation
[byte[]]$headerBytes =  [System.Text.Encoding]::ASCII.GetBytes($($csv2[0]))
[byte[]]$lineBreak = [System.Text.Encoding]::ASCII.GetBytes("`r`n")

for ( $i = ( $csv2.Count - 1 ) ; $i -le ( $csv2.Count - 1 ) ; $i++ ) {
    Out-File -InputObject $csv2[0,$i] -FilePath $Home\csv.csv -Force  ;
    New-MigrationBatch -Name "$($csv[$i-1].EmailAddress)" -AutoStart:$false -CSVData:([System.IO.File]::ReadAllBytes("$Home\csv.csv")) -SourceEndpoint mail.sspc.org -NotificationEmails '.net' 
}

for ( $i = ( $csv2.Count - 1 ) ; $i -lt $csv2.Count ; $i++ ) {
    [byte[]]$MigrationUserBytes = [System.Text.Encoding]::ASCII.GetBytes($($csv2[$i])) ;
    #[byte[]]$bytes = [System.Text.UnicodeEncoding]::ASCII.GetBytes($($csv2[0],"`r`n",$csv2[41])) ;
    [byte[]]$bytes = $headerBytes + $lineBreak + $MigrationUserBytes
    

    #Out-File -InputObject $csv2[0,$i] -FilePath $Home\csv.csv -Force  ;
    New-MigrationBatch -Name "$($csv[$i-1].EmailAddress)" -AutoStart:$false -CSVData:($bytes) -SourceEndpoint mail.sspc.org -NotificationEmails 'ysamorodov@intermedia.net' 
}

