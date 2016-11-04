BEGIN {

    $FileType = '*.cer'
    $BackupPathServer01 = 'C:\Certificates'
    $BackupPathServer02 = "Microsoft.PowerShell.Core\FileSystem::\\Server02\Certificates"
    $CertificatePath = 'Cert:\LocalMachine\Root'
    $RootCertificates = Get-ChildItem -Path $CertificatePath
    
}

PROCESS {

    #region New-CertificateBackup
    
        foreach ( $Certificate in $RootCertificates ) {
        
            $CerFilePath = "$BackupPathServer01\$( $Certificate.Thumbprint ).cer"
            [System.IO.File]::WriteAllBytes( $CerFilePath , ( $Certificate.Export( 'CERT' ) ) )

        }

    #endregion

    #region Copy-Item   
    
        $CopyItemProperties = @{
        
            Path = $BackupPathServer01
            Destination = $BackupPathServer02
            Filter =  $FileType
            Recurse = $true
            Container = $false
            Force = $true
        
        } 

        Copy-Item @CopyItemProperties

    #endregion


    #region Remove-OldCertificates
    
        $Files = ( Get-ChildItem -Path $BackupPathServer01 ) + ( Get-ChildItem -Path $BackupPathServer02 )
        $Date = ( Get-Date ).AddDays( -5 )
        foreach ( $File in $Files ) {

            if ( $File.CreationTime -le $Date ) {
                
                $RemoveItemProperties = @{

                    Path = $File.FullName
                    Confirm = $false
                    Force = $true

                }

                Remove-Item @RemoveItemProperties

            }

        }
    
    #endregion

}



END {



}
