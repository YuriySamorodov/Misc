
$ErrorActionPreference = "Continue"
foreach ( $c in $computers ) {
    $ErrorActionPreference = "Stop"
    try { $IPAddress = Test-Connection $c.Name -Count 1 }
    catch {}
    $IPAddress = $IPAddress.IPV4Address
    if ( $IPAddress ) {
        Invoke-Command -ArgumentList $c, $IPAddress -ComputerName $c.Name -ScriptBlock {
            param ($c, $IPAddress)
            #Set-NetAdapterRss -Name $NetAdapterRss.Name -Enabled:$true
            $NetAdapterRss = Get-NetAdapterRss 
            $properties = @{
                IPAddress = $IPAddress
                RSS = if ( $NetAdapterRss.Enabled ) { "Enabled" } else { "Disabled" }
                Adapter = $NetAdapterRss.Name
            }
            $obj = New-Object psobject -Property $properties
            $obj = $obj | select -ExcludeProperty RunspaceId
            Write-Output $obj
        }
    }
    $ErrorActionPreference = "Continue"
}