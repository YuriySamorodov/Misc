#$logLocation = "H$\Logs\Exchange\V15\TransportRoles\Logs\Hub\AgentLog"
$itemCount = '0'
$servers = get-transportservice ;
$servers = $servers | Where-Object { $_.Name -notmatch "edge" }

$logState = foreach ( $s in $servers ) { 
    $logUNCPath = "\\$($s.Name)\$($s.AgentLogPath -replace "H:","H$")"
    $obj = New-Object psobject ; 
    $obj | Add-Member -MemberType ScriptProperty -Name "Server" -Value { $s.Name } ; 
    #$obj | Add-Member -MemberType ScriptProperty -Name "LocalLogPath" -Value { $s.AgentLogPath } ; 
    $obj | Add-Member -MemberType ScriptProperty -Name "UNCLogPath" -Value { $logUNCPath } ; 
    $obj | Add-Member -MemberType ScriptProperty -Name "AgentLogEnabled" -Value { $s.AgentLogEnabled } ; 
    if ( ( Test-Path $logUNCPath ) -eq $false  ) { 
        $itemCount = '0'
        $logUNCPathExists = 'False'
        } else { 
            $itemCount = Get-ChildItem $logUNCPath -Recurse
            $itemCount = $itemCount.Count ;
            $logUNCPathExists = 'True'
            #$obj | Add-Member -MemberType ScriptProperty -Name 'ItemCount' -Value { $itemCount } 
        } ; 
    $obj | Add-Member -MemberType ScriptProperty -Name 'logUNCPathExists' -Value { $logUNCPathExists } ;
    $obj | Add-Member -MemberType ScriptProperty -Name 'ItemCount' -Value { $itemCount } ;
    Write-Output $obj
}
