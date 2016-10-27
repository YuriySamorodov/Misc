function New-TelnetSession {

    Param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$RemoteHost = $( $_.NameExchange) ,
        [string]$Port = '25'        
        )


       $ErrorActionPreference = 'Continue'
       
       try {

            $Socket = New-Object System.Net.Sockets.TcpClient($RemoteHost,$Port)  
            if ( $Socket ) {
        
            
                $Stream = $Socket.GetStream()
                $Buffer = New-Object System.Byte[] 2048 
                $Encoding = New-Object System.Text.AsciiEncoding         
                Start-Sleep -Milliseconds 4000

                while ( $Stream.DataAvailable ) {
                    
                        $Read = $Stream.Read( $Buffer , 0 , 2048 )
                        $ConsoleOutput = $( $Encoding.GetString( $Buffer , 0 , $Read ) )
                    

                        }

            }
                    
                $Stream.Close() 
            
                }

        catch { 
        
            $ConsoleOutput = "Unable to connect to host: $($RemoteHost):$Port"
            
            }

        #Write-Output $ConsoleOutput

        New-Object psobject -Property @{

            'MXRecord' = $RemoteHost
            'ServerResponse' = $ConsoleOutput

        }

    }
    

   