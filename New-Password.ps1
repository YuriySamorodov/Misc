# Password generator

function New-Password {

    PARAM (
    
      
        [parameter( Mandatory = $false)]
        [ValidateRange(8,16)]
        [int]$MaximumLength = 8,
    
        [parameter( Mandatory = $false)]
        [switch]$ConstantLength = $true,

        [parameter( Mandatory = $false )]
        [ValidateSet('UpperCase','Numbers','SpecialCharacters','All')]
        [string[]]$CharacterSet = 'All'

  
    ) #Param block




    BEGIN {

        #Allowed characters
        # https://azure.microsoft.com/en-us/documentation/articles/active-directory-passwords-policy/
        $CharLower = [char[]] @( 97..122 ) | where { $_ -notmatch "q|l|o|j" } #a..z
        $CharUpper = [char[]] @( 65..90 ) | where { $_ -notmatch "Q|I|L|O" } #A..Z
        $CharNumber = [char[]] @( 50..57 ) #2-9
        $CharSpecial = [char[]] @( 
            33..47 #! " # $ % & ' ( ) * + , - . /
            58..59 #: ;
            61 #=
            63..64 #? @
            91..96 #[ \ ] ^ _ `
            123..126 #{ | } ~
        ) # @ # $ % ^ & * - _ ! + = [ ] { } | \ : ‘ , . ? / ` ~ “ ( ) 

        

        switch ( $CharacterSet -join ',' ) {
            
            { $_ -cnotmatch "U" -and $_ -cmatch "N|S"  } { $CharUpper = $CharLower }
            { $_ -cnotmatch "N" -and $_ -cmatch "U|S"  } { $CharNumber = $CharLower }
            { $_ -cnotmatch "S" -and $_ -cmatch "N|U"  } { $CharSpecial = $CharLower }
            
                
            default {
                
                $CharUpper = $CharUpper
                $CharNumber = $CharNumber
                $CharSpecial = $CharSpecial
                $CharLower = $CharLower
                
                }
       
        }


        if ( $ConstantLength -eq $false ) {
            
            $MaximumLength = Get-Random -Maximum 16 -Minimum 8

        }

    } #Begin block end

    
    
    
    PROCESS {

       $PasswordLength = $maximumLength

       $Password = @(

            Get-Random -InputObject $CharUpper -Count 1 -ErrorAction SilentlyContinue
            Get-Random -InputObject $CharLower -Count ( $PasswordLength - 3 ) -ErrorAction SilentlyContinue
            Get-Random -InputObject $CharNumber -Count 2 -ErrorAction SilentlyContinue
            Get-Random -InputObject $CharSpecial -Count 1 -ErrorAction:0
    
        )

        $Password = $Password -join ''
        Write-Output $Password
   

    } #Process block end

    END {} #End block end


} # New-Password
