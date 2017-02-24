$file = 'D:\Users\ysamorodov\OneDrive\Downloads\57079+SSPC+ImapTasks.csv' ;
$TempFilePath = $HOME
$csv = import-csv $file
$csv2 = $csv | ConvertTo-Csv -NoTypeInformation

for ( $i = ( $csv2.Count - 1 ) ; $i -le ( $csv2.Count - 1 ) ; $i++ ) {
    Out-File -InputObject $csv2[0,$i] -FilePath $Home\csv.csv -Force  ;
    New-MigrationBatch -Name "$($csv[$i-1].EmailAddress)" -AutoStart:$false -CSVData:([System.IO.File]::ReadAllBytes("$Home\csv.csv")) -SourceEndpoint mail.sspc.org -NotificationEmails 'ysamorodov@.net' 
}

for ( $i = ( $csv2.Count - 1 ) ; $i -le ( $csv2.Count - 1 ) ; $i++ ) {
    [byte[]]$bytes = [System.Text.Encoding]::Unicode.GetBytes("$($csv2[0,41])") ;
    [byte[]]$bytes = [System.Text.Encoding]::ASCII.GetBytes($($csv2[0])) + 13 + 10 + [System.Text.Encoding]::ASCII.GetBytes($($csv2[41]))
    #Out-File -InputObject $csv2[0,$i] -FilePath $Home\csv.csv -Force  ;
    New-MigrationBatch -Name "$($csv[$i-1].EmailAddress)" -AutoStart:$false -CSVData:($bytes -split ' ') -SourceEndpoint mail.sspc.org -NotificationEmails 'ysamorodov@intermedia.net' 
}

