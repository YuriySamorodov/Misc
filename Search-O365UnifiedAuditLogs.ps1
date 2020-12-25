function SearchUnifiedAuditLog {
    param (
        $CurrentStart,
        $CurrentEnd
    )
    
    $SearchUnifiedAuditLogParameters = @{
        StartDate = $CurrentStart
        EndDate = $CurrentEnd
        SessionCommand = 'ReturnLargeSet'
        SessionId = New-Guid
        FreeText = "sharepoint\.com"
        ResultSize = 5000
    }
    
    Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters
}