###########
#region ### global:ConvertTo-FormUrlEncoded # Encodes a PSCustomObject into an application/x-www-form-urlencoded body :
###########
function ConvertTo-FormUrlEncoded
{
    <#
    .SYNOPSIS
    Encode a PSCustomObject into an application/x-www-form-urlencoded string.

    .DESCRIPTION
    Invoke-RestMethod does not reliably form-encode a hashtable body across every platform, so this
    helper encodes each property as an escaped key=value pair joined with ampersands. It is used for
    the OAuth2 token endpoint, which expects a form body.

    .PARAMETER Body
    The PSCustomObject whose properties become the form fields.

    .OUTPUTS
    A form-urlencoded string.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Body
    )

    # build each escaped key=value pair
    $pairs = foreach ($property in $Body.PSObject.Properties)
    {
        "{0}={1}" -f $property.Name, [uri]::EscapeDataString([string]$property.Value)
    }# foreach ($property in $Body.PSObject.Properties)

    # join the pairs with ampersands
    return ($pairs -join '&')
}# function ConvertTo-FormUrlEncoded
###########
