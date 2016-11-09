$PSScriptPath = 'C:\Scripts\New-CertificateBackup.ps1'


$NewJobTriggerParamerters = @{

    Daily = $true
    At = "12:00 am"

}

$Trigger = New-JobTrigger @NewJobTriggerParamerters



$NewScheduledJobOptionParameters = @{

    RunElevated = $true
    RequireNetwork = $true
    StartIfOnBattery = $true
    ContinueIfGoingOnBattery = $true
    StartIfIdle = $false
    StopIfGoingOffIdle = $false
    DoNotAllowDemandStart = $false
    MultipleInstancePolicy = 'Queue'


}

$Options = New-ScheduledJobOption @NewScheduledJobOptionParameters



$RegisterScheduledJobParameters = @{

    Name = 'Backup Root Certificates'
    FilePath = $PSScriptPath
    Credential = 'support'
    Authentication = 'Default'
    


}



Register-ScheduledJob @RegisterScheduledJobParameters
