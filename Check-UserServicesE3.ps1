
Connect_MicrosoftGraphAPI -CertificateThumbprint '3BC79C67F5D68ABBDAE90760C57D4E8CD3B2EA12'
Import-Module ConfluencePS
$ServicesKiwi = Get_ConfluenceTable -Credential $UserCredentials -ConfluenceUri https://kiwi.veeam.local/ -PageId 50089042
$ServicesKiwiAllowed = $ServicesKiwi | Where-Object { $_.'Current HD Enablement Process' -match "^Enabled "}
$ServicesKiwiRestricted = $ServicesKiwi | Where-Object { $_.'Current HD Enablement Process' -match "Enable by request"}
$ServicesKiwiProhibited = $ServicesKiwi | Where-Object { $_.'Current HD Enablement Process' -match "Restricted"}

function Test_MsolUserLicense {
    param (
        #[pscredential]$UserCredentials = (Get-Credential),
        [string]$Identity,
        [string]$LicenseName = 'ENTERPRISEPACK'
    )
    #Import-Module MSOnline
    #Connect-MsolService -Credential $CredentialO365
    # $ServicesKiwi = Get_ConfluenceTable -Credential $UserCredentials -ConfluenceUri https://kiwi.veeam.local/ -PageId 50089042
    # $ServicesKiwiAllowed = $ServicesKiwi | Where-Object { $_.'Current HD Enablement Process' -match "^Enabled "}
    $ServicesRestricted = @()
    $servicesToEnable = @()
    $servicesToDisable = @()
    
    $ServicesUser = Get-MgUserLicensePlan -UserPrincipalName $Identity -LicenseName $LicenseName
    
    #Disabled on 2021-01-26 to extend functionality
    # [array]$ServicesCheck = Compare-Object $ServicesUser.ServicePlanName $ServicesKiwiAllowed.ServiceName
    # for ($i = 0 ; $i -lt $ServicesCheck.Count ; $i++ ) {
    #         if ( $ServicesCheck[$i].SideIndicator -eq "=>" ) {
    #             $servicesToEnable += "$($ServicesCheck[$i].InputObject)" 
    #         } 
    #         else { $servicesToDisable += "$($ServicesCheck[$i].InputObject)" 
    #     }
    # }
    foreach ($Service in $ServicesUser){
        if ( $Service.ProvisioningStatus -in @('PendingProvisioning','Success')) {
            if ($Service.ServicePlanName -in $ServicesKiwiProhibited.ServiceName) {
                [array]$servicesToDisable += $Service.ServicePlanName
            } elseif ($Service.ServicePlanName -in $ServicesKiwiRestricted.ServiceName){
                [array]$ServicesRestricted += $Service.ServicePlanName
            }
        } else {
            if ( $Service.ServicePlanName -in $ServicesKiwiAllowed.ServiceName ) {
                [array]$servicesToEnable += $Service.ServicePlanName
            }
        }
    }

    Generate_Output
}

function Connect_MicrosoftGraphAPI {
    param (
        [Alias("Thumbprint","ClientCertificate")]
        [string]$CertificateThumbprint,
        [Alias("ApplicationId","AppId")]
        [string]$ClientId = '15460790-5201-4749-ac72-7812b8d8bffd',
        [string]$TenantId = 'ba07baab-431b-49ed-add7-cbc3542f5140'
    )
    
    #Check certificate location
    
    $Certificate = try {
        Get-ChildItem Cert:\Personal\My\$certificateThumbprint -ErrorAction Stop
    } catch {
        Get-ChildItem Cert:\LocalMachine\My\$certificateThumbprint -ErrorAction Stop
    }

    $props = @{
        Certificate = $Certificate
        ClientId = $ClientId
        TenantId = $TenantId
        ForceRefresh = $true
    }

    Connect-MgGraph @props
    Select-MgProfile -Name Beta
}


function Get-MgUserLicensePlan {
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string[]]$LicenseName,
        [string]$LogPath
    )

    $global:User = Get-MgUser -Filter "UserPrincipalName eq '$UserPrincipalname'"
    [array]$Licenses = Get-MgUserLicenseDetail -UserId $User.Id
    [array]$License = $Licenses | Where-Object { $_.SkuPartNumber -eq $LicenseName }
    [array]$ServicePlans = $License.ServicePlans
    [array]$ServicePlansEnabled = $ServicePlans | Where-Object { $_.ProvisioningStatus -ne 'Disabled' }
    Write-Output $ServicePlansEnabled
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
        $headers = $headers | where {$_ -ne 'Color'}
        $values = $html.all.tags("td") | %{ $_.OuterText }
        #$values = $values | %{ $_ -replace "^$", " " }
        
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



    # function Get-MsolUserLicensePlan {

    #     param (
    #         [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    #         [string]$UserPrincipalName,
    #         [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    #         [string[]]$LicenseName,
    #         [string]$LogPath
    #     )

    #     $user = Get-MsolUser -SearchString $UserPrincipalName
    #     [array]$Licenses = $user.Licenses
    #     [array]$License = $Licenses | where { $_.AccountSku.SkuPartNumber -eq $LicenseName }
    #     $License.ServiceStatus
    # }




#     if ( $ServicesCheck ) {
#         $servicesToEnable = @()
#         $servicesToDisable = @()
#         for ($i = 0 ; $i -lt $ServicesCheck.Count ; $i++ ) {
#             if ( $ServicesCheck[$i].SideIndicator -eq "=>" ) {
#                 $servicesToEnable += "$($ServicesCheck[$i].InputObject)" 
#             } 
#             else { $servicesToDisable += "$($ServicesCheck[$i].InputObject)" 
#         }
#     }
#         $ObjProperties = [ordered]@{
#             DisplayName = $user.DisplayName
#             UserPrincipalName = $user.UserPrincipalName
#             EnabledServices = $ServicesUser.ServicePlan.ServiceName
#             ServicesToEnable = $servicesToEnable
#             ServicesToDisable = $servicesToDisable
#         }

#         New-Object psobject -Property $ObjProperties
# }

function Generate_Output {
    param (
    )
    # if ( $ServicesCheck ) {
    #     $servicesToEnable = @()
    #     $ServicesRestricted = @()
    #     $servicesToDisable = @()
    #     for ($i = 0 ; $i -lt $ServicesCheck.Count ; $i++ ) {
    #         if ( $ServicesCheck[$i].SideIndicator -eq "=>" ) {
    #             $servicesToEnable += "$($ServicesCheck[$i].InputObject)" 
    #         } 
    #         else { $servicesToDisable += "$($ServicesCheck[$i].InputObject)" 
    #     }
    # }
    $ObjProperties = [ordered]@{
        DisplayName = $User.DisplayName
        UserPrincipalName = $User.UserPrincipalName
        EnabledServices = $ServicesUser.ServicePlanName
        ServicesToEnable = $servicesToEnable
        ServicesToDisable = $servicesToDisable
        ServicesRestricted = $ServicesRestricted
    }
    New-Object psobject -Property $ObjProperties
}
