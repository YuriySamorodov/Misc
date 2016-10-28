New Search

for ( $i = 0 ; $i -lt $Mailboxes.Count ; $i++) {

    #region  New-ComplianceSearch

    $ComplianceSearchParameters = @{

        Name = $Mailboxes[$i].UserPrincipalName
        ExchangeLocation = $Mailboxes[$i].UserPrincipalName
        AllowNotFoundExchangeLocationsEnabled = $true
        IncludeUnindexedItemsEnabled = $true

    }

    $ComplianceSearch = New-ComplianceSearch @ComplianceSearchParameters

   #endregion    


    Start-ComplianceSearch $ComplianceSearch
    
    #region New-ComplianceSearchAction

    $ComplianceSearchActionParameters = @{

        SearchName = $ComplianceSearch.Name
        Export = $true
        ArchiveFormat = 'PerUserPst'
        Format = 'FxStream'
        Scope = 'BothIndexedAndUnindexedItems'
        Scenario = 'General'
        Confirm = $true
        Force = $true
 
    }

    New-ComplianceSearchAction @ComplianceSearchActionParameters

    #endregion
