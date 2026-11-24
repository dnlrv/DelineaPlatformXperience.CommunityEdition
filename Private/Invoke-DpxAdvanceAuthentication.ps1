###########
#region ### global:Invoke-DpxAdvanceAuthentication # Submits an answer to an interactive authentication mechanism :
###########
function Invoke-DpxAdvanceAuthentication
{
    <#
    .SYNOPSIS
    Submit an answer to a single interactive authentication mechanism.

    .DESCRIPTION
    Calls the documented /identity/api/Security/AdvanceAuthentication endpoint with the TenantId,
    SessionId, and MechanismId from StartAuthentication plus the Action and Answer for the chosen
    mechanism. Returns the Result object, whose Summary is LoginSuccess when authentication completes.

    .PARAMETER Url
    The tenant host name.

    .PARAMETER TenantId
    The TenantId returned by StartAuthentication.

    .PARAMETER SessionId
    The SessionId returned by StartAuthentication.

    .PARAMETER MechanismId
    The MechanismId of the mechanism being answered.

    .PARAMETER Action
    The advance action, for example Answer, StartOOB, or Poll.

    .PARAMETER Answer
    The answer value for the mechanism. Optional for actions that do not carry an answer.

    .OUTPUTS
    The Result object from the AdvanceAuthentication response.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$Url,

        [Parameter(Mandatory = $true)]
        [System.String]$TenantId,

        [Parameter(Mandatory = $true)]
        [System.String]$SessionId,

        [Parameter(Mandatory = $true)]
        [System.String]$MechanismId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Answer', 'StartOOB', 'Poll')]
        [System.String]$Action,

        [Parameter(Mandatory = $false)]
        [System.String]$Answer
    )

    # the identity security endpoints expect this native-client marker
    $headers = @{ 'X-CENTRIFY-NATIVE-CLIENT' = 'true' }

    # build the request body
    $body = [PSCustomObject]@{ TenantId = $TenantId; SessionId = $SessionId; MechanismId = $MechanismId; Action = $Action }

    # only attach an answer when one was supplied
    if (-not [System.String]::IsNullOrEmpty($Answer))
    {
        $body | Add-Member -MemberType NoteProperty -Name Answer -Value $Answer
    }# if (-not [System.String]::IsNullOrEmpty($Answer))

    # call the documented advance endpoint
    $response = Invoke-RestMethod -Method Post -Uri ("https://{0}/identity/api/Security/AdvanceAuthentication" -f $Url) -Body ($body | ConvertTo-Json) -ContentType 'application/json' -Headers $headers

    # surface API-level failures with a clear message
    if (-not $response.Success)
    {
        throw ("AdvanceAuthentication failed: " + $response.Message)
    }# if (-not $response.Success)

    return $response.Result
}# function Invoke-DpxAdvanceAuthentication
###########
