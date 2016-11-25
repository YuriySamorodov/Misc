#region Credentials 

#region ManualPassword
#Let user enter password


    $AdminCredentialParameters = @{

        Credential = "intermedia\ysamorodov-a"

    }

    $AdminCredential = Get-Credential @AdminCredentialParameters

#endregion NoPassword

#endregion Credentials

#region Reset PF Limits
    
    $ScriptBlock = [scriptblock]::Create(

        {

            BEGIN {

                & 'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1' ;
                Connect-ExchangeServer -auto ;

                 $GetPublicFolderParameters = @{

                        Identity = '\cpnllc-mng'
                        Recurse = $true
                        ResultSize = 'Unlimited'

                    }


                if ( -not $pf ) {

                   $pf = Get-PublicFolder @GetPublicFolderParameters

                }

          
            }

            PROCESS {   

                
                for ( $j = 0 ; $j -lt $pf.Count ; $j++ ) { 
 
                    $WritePFProgressParameters = @{

                        Activity = 'Resetting PF Limits'
                        CurrentOperation = $pf[$j].Name
                        Status = "$percent%"
                        PercentComplete = ( $percent = ( $j / $pf.Count * 100 ) )

                    }

                    Write-Progress @WritePFProgressParameters

                    $SetPublicFoldersParameters = @{

                        Identity = $pf[$j].EntryId
                        IssueWarningQuota = 'Unlimited'
                        ProhibitPostQuota = 'Unlimited'
                        MaxItemSize = 'Unlimited'

                    }

                    Set-PublicFolder @SetPublicFoldersParameters
 
                }

           }

            END {

                Remove-Variable 'pf'

            }

        }
  
    )

    

    $NewJobTriggerParamerters = @{
        
        At = "12:00 am"
        Once = $false
        RepetitionInterval = ( New-TimeSpan -Hours 1 )
        RepetitionDuration = ( New-TimeSpan -Days 30 )
        
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

        Name = "cpnllc-mng Public Folder Limits Reset"
        Credential = $AdminCredential
        Authentication = 'Default'
        Confirm = $false
        Erroraction = 'Stop'
        ScheduledJobOption = $Options
        RunNow = $true
        ScriptBlock =  $ScriptBlock
        Trigger = $Trigger
    
    }

    try { 
 
         Register-ScheduledJob @RegisterScheduledJobParameters

    }

    catch {
        
        Unregister-ScheduledJob $RegisterScheduledJobParameters.Name
        Start-Sleep -Seconds 15
        Register-ScheduledJob @RegisterScheduledJobParameters
    }

#endregion Reset PF Limits