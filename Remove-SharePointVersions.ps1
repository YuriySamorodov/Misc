        #Config Variables
        $SiteURL = "https://veeamsoftwarecorp.sharepoint.com/sites/CIdocuments/"
        $ListName=  "Documents"
        $VersionsToKeep = 10
        
        #Connect to PnP Online
        Connect-PnPOnline -Url $SiteURL -Credentials $creds
        
        #Get the Context
        $Ctx= Get-PnPContext
        
        #Get All Items from the List - Exclude 'Folder' List Items
        $ListItems = Get-PnPListItem -List $ListName -Query "<View Scope='RecursiveAll'><OrderBy Override='TRUE' Ascending='TRUE'><FieldRef Name='ID'/></OrderBy></View>" -PageSize 1000

        ForEach ($Item in $ListItems) {
            if ($item.FileSystemObjectType -eq 'File') {
                #Get File Versions
                $File = $Item.File
                $Versions = $File.Versions
                $Ctx.Load($File)
                $Ctx.Load($Versions)
                $Ctx.ExecuteQuery()
                
                #Write-host -f Yellow "Scanning File:"$File.Name
                $VersionsCount = $Versions.Count
                $VersionsToDelete = $VersionsCount - $VersionsToKeep
                If($VersionsToDelete -gt 0)
                {
                    write-host -f Cyan "`t Total Number of Versions of the File:" $VersionsCount
                    #Delete versions
                    For($i=0; $i -lt $VersionsToDelete; $i++)
                    {
                        write-host -f Cyan "`t Deleting Version:" $Versions[0].VersionLabel
                        $Versions[0].DeleteObject()
                    }
                    $Ctx.ExecuteQuery()
                    Write-Host -f Green "`t Version History is cleaned for the File:"$File.Name
                }
            }
        }    
