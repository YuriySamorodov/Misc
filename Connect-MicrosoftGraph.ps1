function Connect-MicrosoftGraph {
    param (
        $ClientId = "930d79e9-e78f-4865-b550-153c1944cb5c", #Veeam.GraphAPI.ExportTeamsChannel
        $TenantId = "ba07baab-431b-49ed-add7-cbc3542f5140",
        $Thumbprint = '3BC79C67F5D68ABBDAE90760C57D4E8CD3B2EA12'
    )
    $ClientCertificate = Get-ChildItem "cert:\LocalMachine\My\$Thumbprint"
    $MsalToken = Get-MsalToken -ClientId $ClientId -ClientCertificate $ClientCertificate -TenantId $TenantId
    return $MsalToken
}
