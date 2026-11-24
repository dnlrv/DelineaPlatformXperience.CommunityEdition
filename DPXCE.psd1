# DPXCE.psd1 manifest
@{
    RootModule = 'DPXCE.psm1'

    ModuleVersion = '1.0.0'
    GUID = 'd5b830ab-916b-4070-a028-395703da93bd' 
    Author = 'Dan Rivera'

    

    # Only public cmdlets are exported; private helpers stay module-internal
    FunctionsToExport = @('Connect-DpxTenant', 'Invoke-DpxAPI')

    VariablesToExport = @()

    ScriptsToProcess = @()

    CmdletsToExport = @()

    AliasesToExport = @()
}

