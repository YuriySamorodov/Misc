#region Credentials 

#region ManualPassword
#Let user enter password


    $AdminCredentialParameters = @{

        Credential = "IONHARRIS\TasksServiceAccount"

    }

    $AdminCredential = Get-Credential @AdminCredentialParameters

#endregion NoPassword

#endregion Credentials

#region Certificate Backup

    $ScriptBlock = [scriptblock]::Create(

        {

            BEGIN {


                #$PSScriptPath = 'C:\Scripts\New-CertificateBackup.ps1'
                $Date = Get-Date
                $FileType = '*.cer'
                $BackupPathServer01 = 'C:\Certificates'
                $BackupPathServer02 = "Microsoft.PowerShell.Core\FileSystem::\\DC02\Certificates"
                $CertificatePath = 'Cert:\LocalMachine\Root'
                
                $AllRootCertificatesUniqueParameters = @{
                    
                    InputObject = ( Get-ChildItem -Path $CertificatePath | sort )
                    
                    }
                
                $AllRootCertificatesUnique = Get-Unique @AllRootCertificatesUniqueParameters
               
                $RootCertificates = for ( $i = 0 ; $i -lt $AllRootCertificates.Count ; $i++ ) {
 
                    $RootCAFilter = @{
        
                        InputObject = $AllRootCertificates[$i]
                        Property = 'Subject'
                        Value = "CN=IONHARRIS"
                        Contains = $true

                    }

                    Where-Object @RootCAFilter

                }


    
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
        Erroraction = 'Stop'
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
        Register-ScheduledJob @RegisterScheduledJobParametersn
    }

#endregion Certificate Backup
