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

$SecurePasswordParameters = [psobject] @{

        String = 'mvsupport'
        AsPlainText = $true
        Force = $true

    }


    $SecurePassword = ConvertTo-SecureString @SecurePasswordParameters


    $AdminCredentialParameters = [psobject] @{

        TypeName = 'System.Management.Automation.PSCredential'
        ArgumentList = ( 'support' , $SecurePassword )
        
    }


    $AdminCredential =  New-Object @AdminCredentialParameters



$RegisterScheduledJobParameters = @{

    Name = 'Backup Root Certificates'
    FilePath = $PSScriptPath
    Credential = $AdminCredential
    Authentication = 'Default'
    Confirm = $false
    Erroraction = 'Stop'
    


}


try {

    Register-ScheduledJob @RegisterScheduledJobParameters

    }

catch { 

    Unregister-ScheduledJob $RegisterScheduledJobParameters.Name
    #Start-Sleep -Seconds 2
    Register-ScheduledJob @RegisterScheduledJobParameters



    }
