function getdate { 
    Get-Date -Format "YYY-MM-dd HH:mm:ss"
}

function Start-UserPhotoSync {
    param (
        [string]$Identity
    )
    Import-Module ActiveDirectory
    $UserOnPrem = Get-ADUser $Identity -Properties *
    $UserOnPremPhoto = $UserOnPrem.Photo
    $UPN = $UserOnPrem.UserPrincipalName
    if ($UserOnPremPhoto){
        Write-Output "$(getdate) Photo for $UPN located on premises. Updating photo in the cloud"
        ConnectO365 ;
        Set-EXOUserPhoto -Identity $UPN -PictureData $UserOnPremPhoto -Preview
        Set-EXOUserPhoto -Identity $UPN -Save
    }
    else {
        Write-Output "$(getdate) No photo located for $UPN. Checking image in the cloud"
        $UserCloudPhoto = Get-EXOUserPhoto -Identity $UPN
        $UserCloudPhoto = $UserCloudPhoto.PictureData
        if ($UserCloudPhoto) {
            Write-Output "$(getdate) Photo for $UPN located in the cloud. Updating photo on premises"
            Set-ADUser -Identity $UserOnPrem.SamAccountName -Replace @{thumbnailPhoto = $UserCloudPhoto}
        } else {
            Write-Output " $(getdate) No photo for  $UPN  in the cloud or on premises. Please get in touch with the end user"
        }
    }
}

function ConnectO365 {
    param (
        [pscredential]$AdminCredential
    )
    $ConnectionURI = 'https://ps.outlook.com/powershell-LiveID/?proxymethod=RPS'
        
    $ExchangeSessionParameters = [psobject] @{
        ConnectionURI = $ConnectionURI
        ConfigurationName = 'Microsoft.Exchange'
        Authentication = 'Basic'
        AllowRedirection = $true    
        Credential = $AdminCredential
        #SessionOption = $IEConfig
        #AllowClobber = $true
    }
    $ExchangeSession = New-PSSession @ExchangeSessionParameters
    
    $ImportSessionParameters = @{
        Session = $ExchangeSession
        AllowClobber = $true
        Prefix = 'EXO'
        DisableNameChecking = $true
        CommandName = @('Get-Mailbox','Get-UserPhoto','Set-UserPhoto')
    }
    Import-PSSession @ImportSessionParameters | Out-Null
}
