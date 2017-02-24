$file = 'D:\Users\ysamorodov\OneDrive\Intermedia\Downloads\57079+SSPC+ImapTasks.csv' ;
$TempFilePath = $HOME
$csv = import-csv $file
$csv2 = $csv | ConvertTo-Csv -NoTypeInformation

for ( $i = ( $csv2.Count - 1 ) ; $i -le ( $csv2.Count - 1 ) ; $i++ ) {
    Out-File -InputObject $csv2[0,$i] -FilePath $Home\csv.csv -Force  ;
    New-MigrationBatch -Name "$($csv[$i-1].EmailAddress)" -AutoStart:$false -CSVData:([System.IO.File]::ReadAllBytes("$Home\csv.csv")) -SourceEndpoint mail.sspc.org -NotificationEmails 'ysamorodov@intermedia.net' 
}

for ( $i = ( $csv2.Count - 1 ) ; $i -le ( $csv2.Count - 1 ) ; $i++ ) {
    [byte[]]$bytes = [System.Text.Encoding]::Unicode.GetBytes("$($csv2[0,41])") ;
    #Out-File -InputObject $csv2[0,$i] -FilePath $Home\csv.csv -Force  ;
    New-MigrationBatch -Name "$($csv[$i-1].EmailAddress)" -AutoStart:$false -CSVData:($bytes -split ' ') -SourceEndpoint mail.sspc.org -NotificationEmails 'ysamorodov@intermedia.net' 
}

