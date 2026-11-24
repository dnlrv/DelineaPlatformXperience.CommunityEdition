###########
#region ### global:Set-DPXCESession # Finalizes a connection by storing the session globals and confirming :
###########
function Set-DPXCESession
{
    <#
    .SYNOPSIS
    Finalize a Delinea Platform connection.

    .DESCRIPTION
    Every Connect-DpxTenant flow ends here. It builds the authorization header from the access token,
    stores the session splat in $global:DPXCESessionInformation and the connection object in
    $global:DPXCEConnection so all downstream cmdlets can reuse them, then returns a short confirmation.

    .PARAMETER PodFqdn
    The tenant pod FQDN (host name) used to build API URIs.

    .PARAMETER AccessToken
    The bearer access token for the session.

    .PARAMETER User
    Optional user name to display in the confirmation.

    .PARAMETER CustomerId
    Optional customer / tenant identifier to display in the confirmation.

    .OUTPUTS
    A short confirmation object.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$PodFqdn,

        [Parameter(Mandatory = $true)]
        [System.String]$AccessToken,

        [Parameter(Mandatory = $false)]
        [System.String]$User,

        [Parameter(Mandatory = $false)]
        [System.String]$CustomerId
    )

    # build the authorization header used by every downstream API call
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", ("Bearer {0}" -f $AccessToken))

    # store the session splat consumed by Invoke-DpxAPI and Verify-DPXCEConnection
    $Global:DPXCESessionInformation = @{ Headers = $headers; ContentType = "application/json" }

    # build and store the connection object
    $connection = [PSCustomObject]@{
        CustomerId     = $CustomerId
        User           = $User
        PodFqdn        = $PodFqdn
        TenantHostName = $PodFqdn.Split(".")[0]
        AccessToken    = $AccessToken
        LastVerified   = $null
    }

    $Global:DPXCEConnection = $connection

    # confirm the connection
    return ($connection | Select-Object -Property User, PodFqdn | Format-List)
}# function Set-DPXCESession
###########
