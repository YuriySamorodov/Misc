# $PSScriptPath = 'C:\Scripts\New-CertificateBackup.ps1'


$CertificateBackupScript = 




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

$AdminCredential = Get-Credential

$RegisterScheduledJobParameters = @{

    Name = 'Backup Root Certificates'
    # FilePath = $PSScriptPath
    Credential = $AdminCredential
    Authentication = 'Default'
    Confirm = $false
    Erroraction = 'Stop'
    #ScriptBlock = $CertificateBackupScript


}


try {

    Register-ScheduledJob @RegisterScheduledJobParameters -ScriptBlock {`
    
     $FileType = '*.cer' ; $BackupPathDC01 = 'C:\Certificates' ; 
     $BackupPathDC02 = "Microsoft.PowerShell.Core\FileSystem::\\DC02\Certificates" ; 
     $CertificatePath = 'Cert:\LocalMachine\Root' ; 
     $RootCertificates = Get-ChildItem -Path $CertificatePath ; 
     
     foreach ( $Certificate in $RootCertificates ) { 
        
        $CerFilePath = "$BackupPathDC01\$( ( Get-Date -Format "yyyyMMddhhmm" ) + '-'  + $Certificate.Thumbprint ).cer" ; 
        [System.IO.File]::WriteAllBytes( $CerFilePath , ( $Certificate.Export( 'CERT' ) ) ) } ; 
        Copy-Item -Path $BackupPathDC01 -Destination $BackupPathDC02 -Filter  $FileType -Recurse $true -Container:$false -Force:$true ;
        $Files = ( Get-ChildItem -Path $BackupPathDC01 ) + ( Get-ChildItem -Path $BackupPathDC02 ) ; 
        $Date = ( Get-Date ).AddDays( - 5 ) ;
        
        foreach ( $File in $Files ) { 
            if ( $File.CreationTime -le $Date ) { 
            Remove-Item  -Path $File.FullName  -Confirm:$false -Force 
            } 
        }
    
     }
    
    }

catch { 

    Unregister-ScheduledJob $RegisterScheduledJobParameters.Name
    #Start-Sleep -Seconds 2
    Register-ScheduledJob @RegisterScheduledJobParameters -ScriptBlock {`
    
     $FileType = '*.cer' ; $BackupPathDC01 = 'C:\Certificates' ; 
     $BackupPathDC02 = "Microsoft.PowerShell.Core\FileSystem::\\DC02\Certificates" ; 
     $CertificatePath = 'Cert:\LocalMachine\Root' ; 
     $RootCertificates = Get-ChildItem -Path $CertificatePath ; 
     
     foreach ( $Certificate in $RootCertificates ) { 
        
        $CerFilePath = "$BackupPathDC01\$( ( Get-Date -Format "yyyyMMddhhmm" ) + '-'  + $Certificate.Thumbprint ).cer" ; 
        [System.IO.File]::WriteAllBytes( $CerFilePath , ( $Certificate.Export( 'CERT' ) ) ) } ; 
        Copy-Item -Path $BackupPathDC01 -Destination $BackupPathDC02 -Filter  $FileType -Recurse $true -Container:$false -Force:$true ;
        $Files = ( Get-ChildItem -Path $BackupPathDC01 ) + ( Get-ChildItem -Path $BackupPathDC02 ) ; 
        $Date = ( Get-Date ).AddDays( - 5 ) ;
        
        foreach ( $File in $Files ) { 
            if ( $File.CreationTime -le $Date ) { 
            Remove-Item  -Path $File.FullName  -Confirm:$false -Force 
            } 
        }
    
     }



    }
