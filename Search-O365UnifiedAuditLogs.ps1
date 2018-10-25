function SearchUnifiedAuditLog {
    
    $SearchUnifiedAuditLogParameters = @{
        SessionCommand = 'ReturnLargeSet'
        SessionId = New-Guid,
        StartDate = $CurrentStart,
        EndDate = $CurrentEnd,
        FreeText = "sharepoint\.com",
        ResultSize = 5000
    }
    
    Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters
}