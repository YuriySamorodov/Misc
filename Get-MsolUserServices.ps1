$credential = Get-Credential ;
Connect-MsolService -Credential $credential


function GetMsolUserServices {
    param (
        [string]$Identity,
        [array]$Properties = @('DisplayName','UserPrincipalName','WhenCreated')
    )
    $user = Get-MsolUser -SearchString $Identity
    $obj = New-Object psobject
        foreach ( $uProp in $Properties ) {
            $objProperties = @{
                InputObject = $obj
                Name = $uProp
                Value = $($user.$uProp)
                MemberType = 'NoteProperty'
            }
            Add-Member @ObjProperties
            Remove-Variable 'objProperties'
        }
        foreach ($lic in $user.Licenses) {
            $licName = $lic.AccountSku.SkuPartNumber
            $licPlans = $lic.ServiceStatus ;
            foreach ($licPlan in $licPlans) {
                $licPlanName = $licPlan.ServicePlan.ServiceName
                $objProperties = @{
                    InputObject = $obj
                    Name = "$($licName):$($licPlanName)"
                    Value = $licPlan.ProvisioningStatus
                    MemberType = 'NoteProperty'
                }
                Add-Member @objProperties ;
            }
        }
        Write-Output $obj
}


