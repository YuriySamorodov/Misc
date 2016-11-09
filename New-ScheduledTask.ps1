$PSScriptPath = 'C:\Scripts\New-CertificateBackup.ps1'


$NewScheduledTaskPrincipalParameters = @{

    RunLevel = 'Highest'
    UserId = 'NT Authority\System'
    LogonType = 'ServiceAccount'

}

$Principal = New-ScheduledTaskPrincipal @NewScheduledTaskPrincipalParameters


$NewScheduledTaskActionParameters = @{

    Execute = "powershell.exe"
    Argument = "-WindowStyle Hidden -ExecutionPolicy Bypass `"$PSScriptPath`""
    
}

$Action = New-ScheduledTaskAction @NewScheduledTaskActionParameters



$NewScheduledTaskTriggerParamerters = @{

    Daily = $true
    At = "12:00 am"

}

$Trigger = New-ScheduledTaskTrigger @NewScheduledTaskTriggerParamerters



$NewScheduledTaskSettingsSetParameters = @{

    Hidden = $false
    StartWhenAvailable = $true
    AllowStartIfOnBatteries = $true
    DontStopIfGoingOnBatteries = $true
    RunOnlyIfNetworkAvailable = $true
    RunOnlyIfIdle = $false
    DisallowDemandStart = $false
    RestartOnIdle = $true
    
}

$Settings = New-ScheduledTaskSettingsSet @NewScheduledTaskSettingsSetParameters



$NewScheduledTaskParameters = @{

    Principal = $Principal
    Trigger = $Trigger
    Action = $Action
    Settings = $Settings

}


$Task = New-ScheduledTask @NewScheduledTaskParameters



$NewScheduledTaskParameters = @{

    TaskName = 'Backup Root Certificates'
    InputObject = $Task
    Force = $true


}

Register-ScheduledTask @NewScheduledTaskParameters
