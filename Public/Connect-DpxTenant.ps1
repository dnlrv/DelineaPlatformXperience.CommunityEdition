###########
#region ### global:Connect-DpxTenant # Connects the user to a Platform Instance :
###########
function Connect-DpxTenant
{
    <#
    .SYNOPSIS
    Connect to a Delinea Platform instance.

    .DESCRIPTION
    Establishes a session against a Delinea Platform tenant and stores the connection in global
    variables for the current PowerShell session. All other DPXCE cmdlets reuse this connection.

    Two authentication flows are supported:

      - Interactive (default): supply -User. The tenant is queried for its authentication challenges
        and each mechanism is answered. This covers plain username/password and MFA (text answers and
        out-of-bounds challenges). Federation (SAML/OIDC) is detected and reported as unsupported in
        this version.

      - OAuth2: supply -Client and -Secret to obtain a bearer token non-interactively via the
        documented client_credentials grant.

    .INPUTS
    None
    You can't pipe objects into this cmdlet.

    .OUTPUTS
    `System.Object`
    This cmdlet outputs a short confirmation once connected. The connection is stored in global
    variables that exist for this session only.

    .EXAMPLE
    ```powershell
    Connect-DpxTenant -Url yourtenant.delinea.app -User user@domain.com
    ```
    This cmdlet will attempt an interactive connection to yourtenant.delinea.app as user@domain.com. You will
    be prompted for the password and any MFA challenge the tenant requires.

    .EXAMPLE
    ```powershell
    Connect-DpxTenant -Url yourtenant.delinea.app -Client svc-api@domain.com -Secret '***'
    ```
    This cmdlet will obtain a bearer token non-interactively from the documented client_credentials
    grant and connect to yourtenant.delinea.app.

    .NOTES
    Cmdlet info:
    - Author: Daniel Rivera
    - Date: 2026-11-24
    - Version: 1.0
    - Prerequisites: None
    - Permissions: None required.

    .COMPONENT
    DelineaPlatformXperience

    .LINK
    [Original author: Daniel Rivera](https://github.com/dnlrv)
    #>
    [CmdletBinding(DefaultParameterSetName = 'Interactive')]
    param
    (
        # Enter the url to connect to, for example yourtenant.delinea.app.
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Specify the URL to use for the connection (e.g. yourtenant.delinea.app).")]
        [System.String]$Url,

        # Enter the user name to connect as, for example user@domain.com. Interactive authentication flow.
        [Parameter(Mandatory = $true, ParameterSetName = 'Interactive', HelpMessage = "Specify the user name to connect as (e.g. user@domain.com).")]
        [System.String]$User,

        # Enter the OAuth2 client identifier to use for the bearer-token flow (for a service user, its username).
        [Parameter(Mandatory = $true, ParameterSetName = 'OAuth2', HelpMessage = "Specify the OAuth2 client identifier (service-user username).")]
        [System.String]$Client,

        # Enter the OAuth2 client secret to use for the bearer-token flow (for a service user, its password).
        [Parameter(Mandatory = $true, ParameterSetName = 'OAuth2', HelpMessage = "Specify the OAuth2 client secret (service-user password).")]
        [System.String]$Secret,

        # Enter the OAuth2 scope to claim a token for. Defaults to xpmheadless.
        [Parameter(Mandatory = $false, ParameterSetName = 'OAuth2', HelpMessage = "Specify the OAuth2 scope to request.")]
        [ValidateSet('xpmheadless')]
        [System.String]$Scope = 'xpmheadless'
    )

    Write-Verbose ("Connect-DpxTenant invoked. Parameter set: [{0}]." -f $PSCmdlet.ParameterSetName)

    # set TLS 1.2 for all REST calls made during this connection
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Verbose "Enforced TLS 1.2 (SecurityProtocol = Tls12) for REST calls."

    # normalize the url (strip any scheme) so the pod host name is bare
    if ($Url.ToLower().StartsWith("https://"))
    {
        $Url = $Url.Substring(8)
    }# if the url started with https://
    elseif ($Url.ToLower().StartsWith("http://"))
    {
        $Url = $Url.Substring(7)
    }# if the url started with http://
    Write-Verbose ("Normalized pod host: [{0}]." -f $Url)

    # delete any existing connection cache for this session
    $Global:DPXCEConnection = $null
    $Global:DPXCESessionInformation = $null
    Write-Verbose "Cleared any existing session cache (DPXCEConnection, DPXCESessionInformation)."

    # if the OAuth2 bearer-token flow was used
    if ($PSCmdlet.ParameterSetName -eq 'OAuth2')
    {
        Write-Verbose ("Using OAuth2 parameter set. Requesting bearer token via client_credentials grant (scope: {0})." -f $Scope)

        # obtain the bearer token from the documented token endpoint
        $token = Get-DpxOAuthToken -Url $Url -Client $Client -Secret $Secret -Scope $Scope
        Write-Verbose "Bearer token acquired from the token endpoint."

        # finalize the connection with the bearer token
        Set-DPXCESession -PodFqdn $Url -AccessToken $token.access_token -User $Client
        Write-Verbose ("Connection established for [{0}]." -f $Client)
        return
    }# if ($PSCmdlet.ParameterSetName -eq 'OAuth2')

    # interactive flow
    Write-Verbose ("Using Interactive parameter set for user [{0}]." -f $User)
    Write-Host ("Connecting to Delinea Platform (https://{0}) as {1}`n" -f $Url, $User)

    # start the authentication session and discover the challenges
    Write-Verbose "Starting authentication session (StartAuthentication)."
    $startResult = Invoke-DpxStartAuthentication -Url $Url -User $User
    Write-Verbose ("StartAuthentication returned. TenantId [{0}], SessionId [{1}]." -f $startResult.TenantId, $startResult.SessionId)

    # federation is signaled by an IdpRedirectUrl on the result
    if ($startResult.PSObject.Properties.Name -contains 'IdpRedirectUrl')
    {
        Write-Verbose "Federation (SAML/OIDC) detected via IdpRedirectUrl; unsupported in this version."
        throw 'Federation (SAML/OIDC) is not yet supported in this version of Connect-DpxTenant.'
    }# if federation was detected

    # answer every challenge the tenant returned
    foreach ($challenge in $startResult.Challenges)
    {
        Write-Verbose "Processing next authentication challenge."

        # select a mechanism when more than one is offered
        $mechanism = $challenge.Mechanisms
        if (@($mechanism).Count -gt 1)
        {
            Write-Verbose ("{0} mechanism(s) offered for this challenge." -f @($mechanism).Count)
            Write-Host "`n[Available mechanisms]"
            $mechanismIndex = 1
            foreach ($mechanismOption in $mechanism)
            {
                Write-Host ("{0} - {1}" -f $mechanismIndex++, $mechanismOption.PromptSelectMech)
            }# foreach ($mechanismOption in $mechanism)
            $selection = Read-Host "Please select a mechanism [1]"
            if ([System.String]::IsNullOrEmpty($selection))
            {
                # default selection is 1
                $selection = 1
            }# if no selection was made
            if ([int]$selection -gt @($mechanism).Count)
            {
                Write-Verbose ("Invalid mechanism selection [{0}] of [{1}] options." -f $selection, @($mechanism).Count)
                throw 'Invalid mechanism selection. Authentication challenge aborted.'
            }# if invalid selection
            $mechanism = $mechanism[[int]$selection - 1]
        }# if more than one mechanism was offered
        else
        {
            $mechanism = @($mechanism)[0]
        }

        # answer the mechanism according to its answer type
        Write-Verbose ("Answering mechanism [{0}] (AnswerType: {1})." -f $mechanism.MechanismId, $mechanism.AnswerType)
        $authResult = $null
        switch ($mechanism.AnswerType)
        {
            'Text'
            {
                # prompt for the answer as a secure string, then convert it for the request body
                $secureAnswer = Read-Host $mechanism.PromptMechChosen -AsSecureString
                $answer = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureAnswer))
                $authResult = Invoke-DpxAdvanceAuthentication -Url $Url -TenantId $startResult.TenantId -SessionId $startResult.SessionId -MechanismId $mechanism.MechanismId -Action 'Answer' -Answer $answer
            }# 'Text'
            'StartTextOob'
            {
                Write-Verbose "Starting out-of-bounds (OOB) challenge (StartOOB)."
                # start the out-of-bounds challenge, then answer with the code if one is pending
                $authResult = Invoke-DpxAdvanceAuthentication -Url $Url -TenantId $startResult.TenantId -SessionId $startResult.SessionId -MechanismId $mechanism.MechanismId -Action 'StartOOB'
                if ($authResult.Summary -eq 'OobPending')
                {
                    Write-Verbose "OOB code pending; awaiting user entry."
                    $oobAnswer = Read-Host 'Enter the code then press <enter> to finish authentication'
                    $authResult = Invoke-DpxAdvanceAuthentication -Url $Url -TenantId $startResult.TenantId -SessionId $startResult.SessionId -MechanismId $mechanism.MechanismId -Action 'Answer' -Answer $oobAnswer
                }# if the OOB answer is still pending
            }# 'StartTextOob'
            default
            {
                Write-Verbose ("Unsupported mechanism answer type: [{0}]." -f $mechanism.AnswerType)
                throw ("Unsupported mechanism answer type: " + $mechanism.AnswerType)
            }# default
        }# switch ($mechanism.AnswerType)

        Write-Verbose ("Challenge result summary: [{0}]." -f $authResult.Summary)

        # when a challenge completes successfully, finalize the connection
        if ($authResult.Summary -eq 'LoginSuccess')
        {
            $accessToken = $authResult.OAuthTokens.access_token
            Write-Verbose ("LoginSuccess. Finalizing connection for user [{0}]." -f $authResult.User)
            Set-DPXCESession -PodFqdn ($authResult.PodFqdn -replace '/identity', '') -AccessToken $accessToken -User $authResult.User -CustomerId $startResult.TenantId
            return
        }# if ($authResult.Summary -eq 'LoginSuccess')
    }# foreach ($challenge in $startResult.Challenges)

    # if we get here, no challenge reported LoginSuccess
    Write-Verbose "Authentication did not complete; no challenge returned LoginSuccess."
    throw 'Authentication did not complete successfully. Check the response for details.'
}# function Connect-DpxTenant
###########
