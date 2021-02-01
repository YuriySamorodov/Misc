function Test-MsolUserLicense {
    param (
        [pscredential]$CredentialO365 = (Get-Credential),
        [string]$Identity,
        [string]$License = 'ENTERPRISEPACK'
    )
    Import-Module MSOnline
    Connect-MsolService -Credential $CredentialO365
}
    function Get_ConfluenceTable {
        param (
            [pscredential]$Credential,
            [string]$ConfluenceUri,
            [int]$PageID
        )
        # Import-Module ConfluencePS
        Set-ConfluenceInfo -baseUri $ConfluenceUri -Credential $Credential
        $Page = get-ConfluencePage -PageId $PageID
        $body = $page.body
        $html = New-Object -ComObject "HTMLFile"
        
        if ( $PSVersionTable.PSVersion -lt "7.0.0" ) {
            #PowerShell 5 approach
            $html.IHTMLDocument2_write($body)  
        } else {
            #PowerShell 7 approach
            $src = [System.Text.Encoding]::Unicode.GetBytes($body)
            $html.write($src)
        }

        $headers = $html.all.tags("th") | %{ $_.InnerText.Trim() -replace "`r`n", " " }
        $values = $html.all.tags("td") | %{ $_.OuterText }
        #$values = $values | %{ $_ -replace "^$", "N/A" }
        
        for ( $i = 0 ; $i -lt $values.Count ; $i = $i+$headers.Count ) {
            $properties = [ordered]@{}
            for ( $h = 0 ; $h -lt $headers.Count ; $h++) {
                $properties += @{
                    $headers[$h] = $values[$i+$h]
                }
            }
            $obj = New-object psobject -property $properties
            Write-Output $obj
        }
        
    }

    function Get-MgUserLicensePlan {
        param (
            [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
            [string]$UserPrincipalName,
            [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
            [string[]]$LicenseName,
            [string]$LogPath
        )

        $User = Get-MgUser -Filter "UserPrincipalName eq '$UserPrincipalname'"
        [array]$Licenses = Get-MgUserLicenseDetail -UserId $User.Id
        [array]$License = $Licenses | where { $_.SkuPartNumber -eq $LicenseName }
        $License.ServicePlans
    }



    function Get-MsolUserLicensePlan {

        param (
            [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
            [string]$UserPrincipalName,
            [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
            [string[]]$LicenseName,
            [string]$LogPath
        )

        $user = Get-MsolUser -SearchString $UserPrincipalName
        [array]$Licenses = $user.Licenses
        [array]$License = $Licenses | where { $_.AccountSku.SkuPartNumber -eq $LicenseName }
        $License.ServiceStatus
    }

    $ServicesKiwi = Get_ConfluenceTable -Credential $UserCredentials -ConfluenceUri https://kiwi.veeam.local/ -PageId 50089042
    $ServicesKiwiAllowed = $ServicesKiwi | where { $_.'Current HD Enablement Process' -match "^Enabled "}


    $ServicesUser = Get-MsolUserLicensePlan -UserPrincipalName $Identity -LicenseName $LicenseName
    [array]$ServicesCheck = Compare-Object $ServicesUser $ServicesKiwiAllowed
    for ($i = 0 ; $ServicesCheck.Count ; $i++ ) {
            if ( $ServicesCheck[$i].SideIndicator -eq "=>" ) {
                $servicesToEnable += "$($ServicesCheck[$i].InputObject)" 
            } 
            else { $servicesToDisable += "$($ServicesCheck[$i].InputObject)" 
        }
    }

    if ( $ServicesCheck ) {
        $servicesToEnable = @()
        $servicesToDisable = @()
        for ($i = 0 ; $i -lt $ServicesCheck.Count ; $i++ ) {
            if ( $ServicesCheck[$i].SideIndicator -eq "=>" ) {
                $servicesToEnable += "$($ServicesCheck[$i].InputObject)" 
            } 
            else { $servicesToDisable += "$($ServicesCheck[$i].InputObject)" 
        }
    }
        $ObjProperties = [ordered]@{
            DisplayName = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            EnabledServices = $ServicesUser.ServicePlan.ServiceName
            ServicesToEnable = $servicesToEnable
            ServicesToDisable = $servicesToDisable
        }

        New-Object psobject -Property $ObjProperties
}