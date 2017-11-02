Import-Module ActiveDirectory

$Properties = @(
    'msExchRecipientTypeDetails'
    'msExchRecipientDisplayType'
    'mail'
    'DisplayName'
) -split "`n" 


$ADUserProperties = @{
    Filter = { DisplayName -like "*" }
    Properties = $Properties
}

$ADUsers = Get-ADUser @ADUserProperties
$ADUsers = $ADUsers | Sort-Object -Property msExchRecipientTypeDetails

#region Deleting synced users from Office365

for ( $i = 0 ; $i -lt $ADUsers.Count ; $i++ ) {
    if ( $ADUsers[$i].msExchRecipientDisplayType -gt 10 -or $ADUsers[$i].msExchRecipientDisplayType -lt 0 ) {
        $targetAddress = $ADUsers[$i].mail
        Set-ADUser $ADUsers[$i].DistinguishedName -Replace @{ targetAddress = $targetAddress }
        }
}

$InvokeCommandParameters = @{
    ComputerName = 'dc1'
    ScriptBlock = [scriptblock]{Start-ADSyncSyncCycle -PolicyType Initial}
}
Invoke-Command @InvokeCommandParameters

#endregion

