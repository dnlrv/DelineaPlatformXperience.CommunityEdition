###########
#region ### global:Get-DpxOAuthToken # Obtains an OAuth2 access token from the platform token endpoint :
###########
function Get-DpxOAuthToken
{
    <#
    .SYNOPSIS
    Obtain an OAuth2 access token from the Delinea Platform token endpoint.

    .DESCRIPTION
    Calls the documented /identity/api/oauth2/token/xpmplatform endpoint. Supports the client_credentials
    grant (non-interactive service-user / bearer auth) and the refresh_token grant. Returns the raw token
    response, which includes access_token, refresh_token, token_type, expires_in, and scope.

    .PARAMETER Url
    The tenant host name.

    .PARAMETER Client
    The OAuth2 client identifier (for a service user, its username).

    .PARAMETER Secret
    The OAuth2 client secret (for a service user, its password).

    .PARAMETER Scope
    The scope to request. Defaults to xpmheadless.

    .PARAMETER GrantType
    The OAuth2 grant type. Defaults to client_credentials.

    .OUTPUTS
    The token response as a PSCustomObject.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$Url,

        [Parameter(Mandatory = $true)]
        [System.String]$Client,

        [Parameter(Mandatory = $true)]
        [System.String]$Secret,

        [Parameter(Mandatory = $false)]
        [ValidateSet('xpmheadless')]
        [System.String]$Scope = 'xpmheadless',

        [Parameter(Mandatory = $false)]
        [ValidateSet('client_credentials', 'refresh_token')]
        [System.String]$GrantType = 'client_credentials'
    )

    # build the form body for the token request
    $body = [PSCustomObject]@{ grant_type = $GrantType; scope = $Scope; client_id = $Client; client_secret = $Secret }

    # call the documented token endpoint
    $response = Invoke-RestMethod -Method Post -Uri ("https://{0}/identity/api/oauth2/token/xpmplatform" -f $Url) -Body (ConvertTo-FormUrlEncoded $body) -ContentType 'application/x-www-form-urlencoded'

    return $response
}# function Get-DpxOAuthToken
###########