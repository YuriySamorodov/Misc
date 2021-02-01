#requires -runasadministrator

param (
    [CmdletBinding()]
    [int]$attemptCount = 10,
    [int]$AttemptDelay = 10,
    [string]$PhotoPath = 'C:\SCRIPTS\UpdateUserPhoto\AD_Photos',
    [string]$URL = 'http://sharepoint/my',
    [string]$LogFolderPath = 'C:\SCRIPTS\UpdateUserPhoto\Logs',
    [string]$Workflow = @('Export','Import','ExportAndImport'),
    [switch]$KeepOriginalPhoto = $false
)

$DateStart = Get-Date
$attempt = 1
Import-Module ActiveDirectory
Add-PSSnapin Microsoft.SharePoint.PowerShell
$ErrorActionPreference = 'Stop'
$GetADUserParameters = @{
    #Filter = { ThumbnailPhoto -notlike "." }
    SearchBase = 'OU=Accounts,dc=amust,dc=local'
    SearchScope = 'Subtree'
    Properties = 'thumbnailPhoto'
}
[array]$users = Get-ADUser @GetADUserParameters
$users = $users | sort samaccountname
$Site = Get-SPSite -Identity $URL
$context = Get-SPServiceContext -Site $site
$web = Get-SPWeb $URL
$folder =  $web.GetFolder('User Photos/Profile Pictures')
Remove-Item -Path $LogFolderPath -Include *.csv, *.log -Recurse
$logPathParameters = @{
    Path = $LogFolderPath
    ChildPath = "$( Get-Date -Format yyyMMddHHmmss )+tvc+photo+update.log"
}
$logPath = Join-Path @logPathParameters

$csvPathParameters = @{
    Path = $LogFolderPath
    ChildPath = "$( Get-Date -Format yyyMMddHHmmss )+$($users.Count)+amust+user+photos.csv"
}
$csvPath = Join-Path @csvPathParameters
$UPMParameters = @{
    TypeName = [Microsoft.Office.Server.UserProfiles.UserProfileManager]
    ArgumentList = $context
    ErrorAction = 'Stop'
}
$upm = New-Object @UPMParameters

try {
    New-Item -Name $PhotoPath -ItemType Directory | Out-Null
    New-Item $LogFolderPath -ItemType Directory | Out-Null
} catch {}

for ( $i = 0 ; $i -lt $users.Count ; $i++ ) {

    $ID = $null
    $spfile = $null
    Write-Verbose "$( Get-Date )"
    
    #region Progress

        $progressParameters = @{
            Activity = 'Updating user photos...'
            Status = $users[$i].UserPrincipalName
            PercentComplete = $percent = ( $i / $users.Count * 100 -as [int] )
            CurrentOperation = "$percent%"
        }
        Write-Progress @progressParameters
    #endregion
    
    #region Photo Update

       Write-Verbose "$($users[$i].UserPrincipalName)"
       $attempt = 1
       while ( $ID -eq $null ) {
            try {
                $LogMessage = "$( Get-Date );Getting UserProfile for $($users[$i].UserPrincipalname);Attempt #$($attempt)/10;"
                Add-Content -LiteralPath $logPath -Value $LogMessage
                Write-Verbose $LogMessage
                $ID = $upm.GetUserProfile($users[$i].SamaccountName).RecordId
                $LogMessage = "$( Get-Date );Obtained UserProfile for$($users[$i].UserPrincipalname)`n"
                $file = ( $PhotoPath , $users[$i].SamAccountName -join '\' ) + '.jpg'
                $users[$i].thumbnailPhoto | Set-Content $file -Encoding Byte #Export from AD
                $fileStream = ([System.IO.FileInfo] ( Get-Item $file ) ).OpenRead()
                $spFile = "$( $folder.ServerRelativeUrl )/0c37852b-34d0-418e-91c6-2ac25af4be5b_$ID.jpg"
                $folder.Files.Add($spFile,[System.IO.Stream]$fileStream, $true) | Out-Null
                $fileStream.Close(); 
            }
            catch {
                if ( $attempt -lt $attemptCount ) {
                        $LogMessage = "$( Get-Date );Profile for $( $users[$i].SamaccountName) could not be located;Will retry in 10 seconds.;"
                        Add-Content -LiteralPath $logPath -Value $LogMessage
                        Write-Verbose $LogMessage
                        Start-Sleep -Seconds 10
                    } else { 
                        $LogMessage = "$( Get-Date );Profile for $( $users[$i].SamaccountName) could not be located;;$($_.Exception.Message)"
                        Add-Content -LiteralPath $logPath -Value $LogMessage
                        Write-Warning $LogMessage
                        break
                    }
                }
            finally {
                $attempt++
            }
       }
       
       
       $LogMessage = "$( Get-Date );Processing $($users[$i].UserPrincipalName) completed;"
       Add-Content -LiteralPath $logPath -Value $LogMessage
       Write-Verbose $LogMessage
    
    #endregion Photo Update 

    #region CSV
 
    $csvEntry = [pscustomobject]@{
        ID = $ID
        SamaccountName = $users[$i].SamAccountName
        UserPrincipalName = $users[$i].UserPrincipalName
        File = $file
    }

    $CsvExportParameters = @{
        InputObject = $csvEntry
        LiteralPath = $csvPath
        NoTypeInformation = $true
        Append = $true
    }
    Export-Csv @CsvExportParameters
     
}
    #endregion


Try{
    $LogMessage = "$( Get-Date);Update Profile Photo Service Started;"
    Add-Content -LiteralPath $logPath -Value $LogMessage
    $UpdateSPProfilePhotoStorePararmeters = @{
        MySiteHostLocation = $URL
        CreateThumbnailsForImportedPhotos = $true
        NoDelete = $( $KeepOriginalPhoto.IsPresent )
    }
    Update-SPProfilePhotoStore @UpdateSPProfilePhotoStorePararmeters
    $LogMessage = "$( Get-Date);Update Profile Photo Service Completed;"
    Add-Content -LiteralPath $logPath -Value $LogMessage
}
 Catch [System.Exception]{
    $LogMessage = "$( Get-Date);Update Profile Photo Service Failed;$($Error[0].Exception.Message)"
    Add-Content -LiteralPath $logPath -Value $LogMessage
    Write-Host "Unable to update Profile Photo Store! Folowing exception occurred: $($Error[0].Exception.Message)"
}
 Finally {
    $DateEnd = Get-Date
    $Duration = $DateEnd - $DateStart
    Add-Content -LiteralPath $logPath -Value "Script started at $DateStart"
    Add-Content -LiteralPath $logPath -Value "Script completed at $DateEnd"
    Add-Content -LiteralPath $logPath -Value "Script run time $( $Duration -f "{0:c}" )"
    Write-Output "Script started at $DateStart"
    Write-Output "Script completed at $DateEnd"
    Write-Output "Script run time $( $Duration -f "{0:c}" )"
}
