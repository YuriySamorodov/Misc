#requires -runasadministrator

param(
   [Parameter(Mandatory = $true,
              Position = 1,
              ValueFromPipeline = $true,
              ValueFromPipelineByPropertyName = $true,
              HelpMessage = 'Enter library name (not full address)'
   )]
   [string]$LibraryName,
   [string]$Site,
   [string]$ExportPath
)

Add-PSSnapin * ;

try {
    $web = Get-SPWeb $site
    $items = $web.Lists[$libraryName].Items.GetDataTable()
    $descriptionReplace = "<.+?>|`n|\&quot\;|\&\#160|\&\#58"
    
   foreach ( $item in $items ) {
         foreach ( $property in $item.psobject.Properties ) {
            $AddMemberProperties = @{
                InputObject = $item
                MemberType = 'NoteProperty'
                Name = $property.Name
                Value = ( $property.Value -replace $descriptionReplace )
                Force = $true
            }
            Add-Member @AddMemberProperties
        }
    }     
}

catch {
   Write-Warning $Error[-1].Exception.Message
}

finally {
    Write-Output $items
}
