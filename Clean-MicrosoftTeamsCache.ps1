$currentPowerShell =  Get-Process -PID $PID
$processes = Get-Process outlook, teams
$processes | Where-Object { $_.SI -eq $currentPowerShell.SI }


$directories = Get-ChildItem -Path "C:\$env:HOMEPATH\AppData\Roaming\Microsoft\Teams" -Directory 
$directories = $directories | Where-Object { $_ -in ('Cache','databases','blob_storage','IndexedDB','') }
$directories | Remove-Item -Recurse -Force 

