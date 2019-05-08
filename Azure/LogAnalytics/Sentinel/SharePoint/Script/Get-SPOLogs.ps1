$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'
$Error.Clear()
$Priority = 'Normal'
$Timeout = New-TimeSpan -Seconds 30
$DebugFolder = 'C:\Users\yury.samorodov\Downloads\Azure\LogAnalytics\Sentinel\SharePoint\Debug'
$DebugFileName  = "$( Get-Date -f "yyy-MM-dd" )-SPO-Daily-Debug.log"
$DebugFilePath = Join-Path -Path $DebugFolder -ChildPath $DebugFileName
if ( Test-Path  $DebugFilePath ) {
Remove-Item $DebugFilePath -Confirm:$false -Force
}

Start-Transcript -LiteralPath $DebugFilePath -IncludeInvocationHeader -Force -Append


#Authentication
$UserName = 'yuriy.samorodov@veeam.com'
$Password = ''
$Password = ConvertTo-SecureString -String $Password -AsPlainText -Force
$creds = [pscredential]::new($UserName,$Password)
$TenantId = 'ba07baab-431b-49ed-add7-cbc3542f5140'


Connect-AzAccount -Tenant $TenantId -Credential $creds

$Date = Get-Date
$Date = $Date.AddDays(-1)
$Date = $Date.ToString("yyy-MM-dd")

$LogFolder = 'C:\Users\yury.samorodov\Downloads\Azure\LogAnalytics\Sentinel\SharePoint\SharePoint Logs'
$LogFileName = $Date + "-SPO-" + "Results" + '.csv'
$LogFilePath = Join-Path -Path $LogFolder -ChildPath $LogFileName


$QueryFolder = "C:\Users\yury.samorodov\Downloads\Azure\LogAnalytics\Sentinel\SharePoint\Script\"
$QueryName = 'query.kql'
$QueryPath = Join-Path -Path $QueryFolder -ChildPath $QueryName
$Query = Get-Content $QueryPath

$QueryParameters = @{
    WorkspaceId = '89e416d8-1e74-4d89-857a-b9345a8505a4'
    Query = [string]$Query
    ErrorAction = 'Stop'
    Debug = $false
    IncludeStatistics = $true
    IncludeRender = $true
}

$QueryResults = Invoke-AzOperationalInsightsQuery @QueryParameters

if ( $Error.Count -gt 0 ) {
    do {
        $Error.Clear()
        $Timeout += $Timeout
        $QueryResults = Invoke-AzOperationalInsightsQuery @QueryParameters
    } until ( 
        $Error.Count -eq 0 
        )
}

do { 
Start-Sleep -Seconds $Timeout.TotalSeconds
}
until ( $QueryResults.Results -ne $null )

if ( $Error.Count -eq 0 ) {
$QueryResults.Results | Export-Csv -Notypeinformation -Path $LogFilePath -Append
} else { 
$Priority = 'High'
}

Write-Debug $QueryResults.Statistics
Write-Debug $QueryResults.Render


$MailMessageParameters = @{
    From = 'yuriy.samorodov@veeam.com'
    To = 'yuriy.samorodov@veeam.com'
    SmtpServer = 'outlook.office365.com'
    Port = '587'
    UseSSL = $true
    Encoding = 'UTF8'
    Priority = $Priority
    Subject = $MessageSubject
    Body = $MessageBody
    BodyAsHTML = $true
}

Stop-Transcript
