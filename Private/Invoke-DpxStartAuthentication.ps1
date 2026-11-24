###########
#region ### global:Invoke-DpxStartAuthentication # Begins an interactive authentication session :
###########
function Invoke-DpxStartAuthentication
{
    <#
    .SYNOPSIS
    Start an interactive authentication session against a Delinea Platform tenant.

    .DESCRIPTION
    Calls the documented /identity/api/Security/StartAuthentication endpoint. The tenant returns a
    Result object containing the SessionId, TenantId, and an array of Challenges, each with one or
    more Mechanisms that must be answered through Invoke-DpxAdvanceAuthentication.

    .PARAMETER Url
    The tenant host name, for example yourtenant.delinea.app.

    .PARAMETER User
    The user name to authenticate.

    .OUTPUTS
    The Result object from the StartAuthentication response.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$Url,

        [Parameter(Mandatory = $true)]
        [System.String]$User
    )

    # the identity security endpoints expect this native-client marker
    $headers = @{ 'X-CENTRIFY-NATIVE-CLIENT' = 'true' }

    # StartAuthentication only needs the user; the password is answered later
    $body = [PSCustomObject]@{ User = $User; Version = '1.0' }

    # call the documented interactive start endpoint
    $response = Invoke-RestMethod -Method Post -Uri ("https://{0}/identity/api/Security/StartAuthentication" -f $Url) -Body ($body | ConvertTo-Json) -ContentType 'application/json' -Headers $headers

    # surface API-level failures with a clear message
    if (-not $response.Success)
    {
        throw ("StartAuthentication failed: " + $response.Message)
    }# if (-not $response.Success)

    return $response.Result
}# function Invoke-DpxStartAuthentication
###########
