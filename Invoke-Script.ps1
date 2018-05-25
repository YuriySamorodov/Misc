function Invoke-Script {
    param (
    [string]$ComputerName,
    [scriptblock]$ScriptBlock,
    [pscredential]$Credential
)

    BEGIN {
        $Computers = Get-ADComputer -Filter "Name -like '$ComputerName*'" ;
        $DNSNames = $Computers | Resolve-DnsName -Type A ;
        $IPAddresses = $DNSNames | Select-Object -ExpandProperty IPAddress ;
    }

    PROCESS {
        $InvokeCommandProperties = @{
            Authentication = 'Negotiate'
            Credential = $Credential
            ComputerName = $IPAddresses
            ScriptBlock = $ScriptBlock
        }
        Invoke-Command @InvokeCommandProperties
    }

    END {}

}
