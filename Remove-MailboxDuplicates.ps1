$UserName = 'test@smsllaw.test'
$Password = 'dsgfdgdgfdsgfs!'
$Server = 'west.exch.serve.net'

$SecurePasswordParameters = [psobject] @{
    String = $Password
    AsPlainText = $true
    Force = $true
}
$SecurePassword = ConvertTo-SecureString @SecurePasswordParameters
  
$AdminCredentialParameters = [psobject] @{
    TypeName = 'System.Management.Automation.PSCredential'
    ArgumentList = ( $UserName , $SecurePassword ) 
}
$AdminCredential =  New-Object @AdminCredentialParameters


$Users = @(

'ELonardo@smsllaw.com
JMeehan@smsllaw.com
dfaiza@smsllaw.com
NChinchilla@smsllaw.com
JLibby@smsllaw.com
MSylvia@smsllaw.com
MHomonoff@smsllaw.com
JReed@smsllaw.com
KPale@smsllaw.com
KOlson@smsllaw.com
KChartier@smsllaw.com
RDeLaiarro@smsllaw.com
bsiter@smsllaw.com
KAuclair@smsllaw.com
HWeiner@smsllaw.com
JWeiner@smsllaw.com
LMarcello@smsllaw.com
MIacono@smsllaw.com
DPederzani@smsllaw.com
CCiresi@smsllaw.com
MLeonard@smsllaw.com
MMcGowan@smsllaw.com
genesys@smsllaw.com
ALeonard@smsllaw.com'

) -split "`n"  


for ( $i = 0 ; $i -lt $Users.Count ; $i++ ) {


#region Progress

    $progressParameters = @{
    
        'Activity' = 'Running deduplication...'
        'Status' = $users[$i]
        'PercentComplete' = $percent = ( $i / $Users.Count * 100 -as [int] )
        'CurrentOperation' = "$percent%"
    }

    Write-Progress @progressParameters

       

#endregion

   $RemoveDuplicatesParameters = [psobject] @{
    Identity = ( $Users[$i] ).ToString().Trim()
    Server = $Server
    Credentials = $AdminCredential
    Impersonation = $true
    Retain = 'Newest'
    DeleteMode = 'SoftDelete'
    Type = 'All'
    ExcludeFolders = '#DeletedItems#'
    MailboxWide = $true
    Confirm = $false
    Force = $true
   }

   & C:\Users\support\Downloads\Remove-DuplicateItems.ps1 @RemoveDuplicatesParameters
}
