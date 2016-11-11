#$PSScriptPath = 'C:\Scripts\New-CertificateBackup.ps1'

#Get-Credential -Credential 

#region Credentials

$UserName = 'support'
$Password = 'mvsupport'

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


$AdminCredential = New-Object @AdminCredentialParameters


#endregion

#region Certificate Backup

$ScriptBlock = [scriptblock]::Create(


    {


        BEGIN {

            $Date = Get-Date
            $FileType = '*.cer'
            $BackupPathServer01 = 'C:\Certificates'
            $BackupPathServer02 = 'C:\Certificates1'
            $CertificatePath = 'Cert:\LocalMachine\Root'
            $RootCertificates = Get-ChildItem -Path $CertificatePath

    
        }

        PROCESS {   

        #region New-CertificateBackup
        #Reading Certificate store and creating *.cer files
    
            foreach ( $Certificate in $RootCertificates ) {
              
                $JoinPathParameters = @{

                    ChildPath = @(
                        $($Date.ToString("yyyyMMddhhmm") )
                        "$($Certificate.Thumbprint).cer"
                        ) -join "+"
                    
                    Path = $BackupPathServer01


                }
                
                $CerFilePath = Join-Path @JoinPathParameters

                $export = ( $Certificate.Export( 'CERT' ) )

                [System.IO.File]::WriteAllBytes( $CerFilePath, $export )
                                               

            }

        #endregion

        #region Copy-Item
        #Copy certificate files to DC02   
    
            $CopyItemProperties = @{
        
                Path = $BackupPathServer01
                Destination = $BackupPathServer02
                Filter =  $FileType
                Recurse = $true
                Container = $false
                Force = $true
        
            } 

            Copy-Item @CopyItemProperties

        #endregion

        #region Remove-OldCertificates
        #Removing 5 days old certificates from both DC01 and DC02
    
            $Files = Get-ChildItem $BackupPathServer01, $BackupPathServer02
            $TresholdDate = $Date.AddDays( -5 )
            
            foreach ( $File in $Files ) {

                if ( $File.CreationTime -le $TresholdDate ) {
                
                    $RemoveItemProperties = @{

                        Path = $File.FullName
                        Confirm = $false
                        Force = $true

                    }

                    Remove-Item @RemoveItemProperties

                }

            }
    
        #endregion

        }

        END {



        }

    }
  
)

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


$ErrorActionPreference = 'Stop'

$RegisterScheduledJobParameters = @{

    Name = 'Backup Root Certificates'
    #FilePath = $PSScriptPath
    Credential = $AdminCredential
    Authentication = 'Default'
    Confirm = $false
    #Erroraction = 'Stop'
    ScheduledJobOption = $Options
    RunNow = $true
    ScriptBlock =  $ScriptBlock
    
}




try { 
 
     Register-ScheduledJob @RegisterScheduledJobParameters
    
}

catch {
        
    Start-Sleep -Seconds 15
    Unregister-ScheduledJob $RegisterScheduledJobParameters.Name


}

