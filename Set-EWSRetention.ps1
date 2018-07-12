
    #[cmdletbinding()]
    #Variable
    <#
    $UserName = "yuriy.samorodov@veeam.com"
    $Password = 'K0nstantin1995!';
    $Tenant = "veeamsoftwarecorp.onmicrosoft.com"
    $global:uri = 'https://outlook.office365.com/EWS/Exchange.asmx'
    #GUID of the 'Personal never move to archive' retention tag
    $ArchiveTagGUID = '142d0b7c-2c73-43d2-a97d-04a495c24ccb'
    #>

    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$global:UserName = 'svc-backup-ExchO@veeam.com',
        [Parameter(Mandatory=$false,Position=1)]
        [string]$global:Password = 'Bw5x$bEyk*QJ',
        [Parameter(Mandatory=$false,Position=2)]
        [ValidateSet('Calendar','Contacts','Notes','Tasks','All')]
        [string[]]$global:Folders = 'Calendar',
        [Parameter(Mandatory=$false,Position=3)]
        [string[]]$global:Mailboxes = 'yuriy.samorodov@veeam.com',
        [Parameter(Mandatory=$false,Position=4)]
        [system.uri]$global:Tenant = 'veeamsoftwarecorp.onmicrosoft.com',
        [Parameter(Mandatory=$false,Position=100)]
        [string]$global:uri = 'https://outlook.office365.com/EWS/Exchange.asmx'
    )

    BEGIN {

        function EWSCheck {
            $path = 'C:\Program Files\Microsoft\Exchange\Web Services\' ;
            $dllParams = @{
                Path = $path ;
                Include = 'Microsoft.Exchange.WebServices.dll';
                File = $true
                Recurse = $true
                ErrorAction = 'SilentlyContinue'
            }
            $global:ewsDLL = Get-ChildItem @dllParams
            if ( $ewsDLL -eq $null ) {
                Write-Output "Please download and install Microsoft EWS Mananged API https://goo.gl/wkPtak"
            }
        }

        function EWSConnection ($uri,$UserName,$Password,$Tenant) {
            Import-Module $ewsDLL ;
            $serviceParams = @{
                TypeName = 'Microsoft.Exchange.WebServices.Data.ExchangeService'
                ArgumentList = [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2010_SP1
            }
            $global:service = New-Object @serviceParams
        
            $global:uriParams = @{
                TypeName = 'uri'
                ArgumentList = $global:uri
            }
            $global:service.url = New-Object @uriParams

            <#
            $EWSCredsParams = @{
                TypeName = 'Microsoft.Exchange.WebServices.Data.WebCredentials'
                ArgumentList = @(
                    $UserName
                    $Password
                    $Tenant
                )
            }
            $global:EWSCreds = New-Object @EWSCredsParams
            $global:service.Credentials = $EWSCreds
            }
            #>

            $EWSCredsParams = @{
                TypeName = 'Microsoft.Exchange.WebServices.Data.WebCredentials'
                ArgumentList = @(
                    $UserName
                    $Password
                    $Tenant
                )
            }
            $global:EWSCreds = New-Object @EWSCredsParams
            $global:service.Credentials = $EWSCreds
            $global:service.EnableScpLookup = $false
            $global:service.PreAuthenticate = $true
        }




        function EWSMailboxImpersonation ($mbx) {
            $global:ImpersonatedUserParams = @{
                TypeName = 'Microsoft.Exchange.WebServices.Data.ImpersonatedUserId'
                ArgumentList = @(
                    [Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress
                    $mbx
                )
            }
            $global:service.ImpersonatedUserId = New-Object @global:ImpersonatedUserParams
        }

        function EWSFolderView () {
            $FolderViewParams = @{
                TypeName = 'Microsoft.Exchange.WebServices.Data.FolderView'
                ArgumentList = 1
            }
            $global:FolderView = New-Object @FolderViewParams
        }

        function SearchFilter ($FolderName) {
            $SearchFilterParams = @{
                TypeName = 'Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo'
                ArgumentList = @(
                    [Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName
                    $FolderName
                )
            }
            $global:SearchFilter = New-Object @SearchFilterParams
        }


        function FolderFind () {
          $global:FolderFind = $global:service.FindFolders(
                [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot,
                $global:SearchFilter,
                $global:FolderView
                )
        }
    
        function FolderBind () {
            $global:Folder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind(
                $service,
                $FolderFind.Folders[0].Id
                )
        }

        function ArchiveTag () {
            $ArchiveTagParams = @{
                TypeName = 'Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition'
                ArgumentList = @(
                    '0x3018'
                    [Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Binary
                )
            }
            $global:ArchiveTag = New-Object @ArchiveTagParams
        }

        function RetentionFlags {
            $global:RetentionFlagsParams = @{
                TypeName = 'Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition'
                ArgumentList = @(
                    '0x301D'
                    [Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Integer
                )
            }
            $global:RetentionFlags = New-Object @RetentionFlagsParams
        }

        function RetentionPeriod {
            $RetentionPeriodParams = @{
                TypeName = 'Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition'
                ArgumentList = @(
                    '0x301E'
                    [Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Integer
                )
            }
            $global:RetentionPeriod = New-Object @RetentionPeriodParams
        }

    }


    PROCESS {
        EWSCheck ;
        EWSConnection ;
        #EWSFolderView ;
        ArchiveTag ;
        RetentionPeriod ;
        RetentionFlags ;

        for ( $i = 0 ; $i -lt $Mailboxes.Count  ; $i++ ) {
            . EWSMailboxImpersonation $Mailboxes[$i]
            for ( $f = 0 ; $f -lt $Folders.Count ; $f++ ) {
                SearchFilter($Folders[$f])
                EWSFolderView
                FolderFind
                FolderBind
                $Folders[$f].SetExtendedProperty($global:RetentionFlags, 16)
                $Folders[$f].SetExtendedProperty($global:RetentionPeriod, 0)
                $Folders[$f].Update()
            }
        }
    }

    END {
        $service.ImpersonatedUserId = $null
    }
