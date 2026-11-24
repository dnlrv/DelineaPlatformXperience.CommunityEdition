###########
#region ### global:Invoke-DpxAPI # CMDLETDESCRIPTION : Invoke any RestAPI endpoint in a connected Delinea Platform instance :
###########
function Invoke-DpxAPI
{
    <#
    .SYNOPSIS
    Interacts with any RestAPI endpoint in a connected Delinea Platform instance.

    .DESCRIPTION
    This cmdlet provides an easy way to interact with any RestAPI endpoint in a Delinea Platform instance. It requires an existing, valid $DPXCEConnection
    to exist.

    This cmdlet has 2 forms, depending on which endpoints need to be accessed:

      - If the endpoint is a pure delinea.app endpoint, like myurl.delinea.app/identity/api/UserMgmt/GetUserInfo, then the default is just to use
        this cmdlet with the -APICall parameter and type in the endpoint uri after the *.delinea.app portion.
        - For example, Invoke-DpxAPI -APICall identity/api/UserMgmt/GetUserInfo
      - If the endpoint is a Secret Server endpoint, like api/v1/folders, then the full uri needs to be typed out using the override parameter.
        - For example, Invoke-DpxAPI -OverrideUriAPI myurl.secretservercloud.com/api/v1/folders

    .INPUTS
    None
    You can't pipe objects into this cmdlet.

    .OUTPUTS
    `System.Management.Automation.PSCustomObject`
    This cmdlet outputs a PSCustomObject with the requested data if the RestAPI call was successful.

    .EXAMPLE
    ```powershell
    Invoke-DpxAPI -APICall identity/api/UserMgmt/GetUserInfo
    ```
    This will attempt to reach the identity/api/UserMgmt/GetUserInfo RestAPI endpoint in the currently connected Platform instance. If there is a
    valid connection, information about the connected user will be returned as output.

    .EXAMPLE
    ```powershell
    Invoke-DpxAPI -OverrideUriAPI myurl.secretservercloud.com/api/v1/folders -Body $folderjson
    ```
    This will attempt to reach the Secret Server Folder RestAPI endpoint in the currently connected Platform instance. If there is a
    valid connection, performs a POST action based on what the $folderjson body payload contains.

    .EXAMPLE
    ```powershell
    Invoke-DpxAPI -OverrideUriAPI myurl.secretservercloud.com/api/v1/users/current -Method GET
    ```
    This will attempt to reach the Secret Server Folder RestAPI endpoint in the currently connected Platform instance. If there is a
    valid connection, performs a GET action.

    .NOTES
    Cmdlet info:
    - Author: Daniel Rivera
    - Date: 2026-11-24
    - Version: 1.0
    - Prerequisites: An active $DPXCEConnection
    - Permissions: Depends on the target endpoint.

    .COMPONENT
    DelineaPlatformXperience

    .LINK
    [Original author: Daniel Rivera](https://github.com/dnlrv)
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    param
    (
        # Specify the RestAPI endpoint to target. For example "identity/api/UserMgmt/GetUserInfo" or "inventory/api/types/computer".
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Specify the API call to make.", ParameterSetName = "Default")]
        [System.String]$APICall,

        # Specify the full uri to override, primarily used for Secret Server endpoints. Overrides the domain name completely.
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Specify the API call to make. Overrides the domain name completely. Mostly used for Secret Server endpoints.", ParameterSetName = "Override")]
        [System.String]$OverrideUriAPI,

        # Specify the JSON Body payload.
        [Parameter(Position = 1, Mandatory = $false, HelpMessage = "Specify the JSON Body payload.")]
        [System.String]$Body,

        # Specify the Method to use with this call. Default is POST.
        [Parameter(Mandatory = $false, HelpMessage = "Method to use on the Invoke-WebRequest.")]
        [ValidateSet("GET","POST","PATCH","OPTIONS","PUT")]
        [System.String]$Method = "POST",

        # Keep the full response object in $global:LastPlatformResponse after the call.
        [Parameter(Mandatory = $false, HelpMessage = "Specify the API call to make.", ParameterSetName = "Default")]
        [Parameter(Mandatory = $false, HelpMessage = "Specify the API call to make.", ParameterSetName = "Override")]
        [Switch]$KeepResponse

    )

    Write-Verbose ("Invoke-DpxAPI invoked. Parameter set [{0}], Method [{1}]." -f $PSCmdlet.ParameterSetName, $Method)

    # verifying an active Platform connection
    Verify-DPXCEConnection
    Write-Verbose "Active Platform connection verified."

    if ($PSCmdlet.ParameterSetName -eq "Override")
    {
        $uri = $OverrideUriAPI
        # if URL provided doesn't have "https://" in front, add it.
        if ($uri.ToLower().Substring(0,8) -ne "https://")
        {
            $uri = ("https://{0}" -f $uri)
        }
        Write-Verbose ("Override parameter set: target URI [{0}]." -f $uri)
    }# if ($PSCmdlet.ParameterSetName -eq "Override")
    else 
    {
        # setting the url based on our DPXCEConnection information
        $uri = ("https://{0}/{1}" -f $global:DPXCEConnection.PodFqdn, $APICall)
        Write-Verbose ("Default parameter set: target URI [{0}]." -f $uri)
    }

    # Try
    Try
    {
        Write-Verbose ("Uri=[{0}]" -f $uri)

        # if the -Body parameter was used
        if ($PSBoundParameters.ContainsKey('Body'))
        {
            # redacted: log only the payload size, never the body contents (may hold secret values)
            Write-Verbose ("Body present. Length [{0}] bytes (payload not logged)." -f $Body.Length)
            Write-Verbose ("Sending [{0}] request to [{1}]." -f $Method, $uri)
            # making the call using our a Splat version of our connection
            $Response = Invoke-RestMethod -Method $Method -Uri $uri -Body $Body @global:DPXCESessionInformation
        }
        else # otherwise
        {
            Write-Verbose ("Sending [{0}] request to [{1}]." -f $Method, $uri)
            # making the call using our a Splat version of our connection
            $Response = Invoke-RestMethod -Method $Method -Uri $uri @global:DPXCESessionInformation
        }

        Write-Verbose ("Response received. Success=[{0}]." -f $Response.Success)

        # if the response was successful, some Platform endpoints have a Response property as part of the response
        if ($Response.Success)
        {
            if ($Response.Result -ne $null)
            {
                Write-Verbose "Returning Response.Result."
                # return the results
                return $Response.Result
            }
            if ($Response.records -ne $null) # this is for Secret Server responses
            {
                Write-Verbose "Returning Response.records (Secret Server shape)."
                return $Response.records
            }

            Write-Verbose "Returning full Response object (no Result/records)."
            return $Response
        }# if ($Response.Success)
        else
        {
            # otherwise return the response
            Write-Verbose "Response.Success not true; returning raw response object."
            return $Response
        }
    }# Try
    Catch
    {
        Write-Verbose ("Request failed: [{0}]." -f $_.Exception.Message)
        $e = New-Object DPXCEException -ArgumentList ("A Platform error has occured. Check `$LastDPXCEError for more information")
		$e.AddAPIData($ApiCall, $Method, $Body, $Response)
		$e.AddExceptionData($_)
        $e.AddData("OverrideUriAPI",$OverrideUriAPI)
        Write-Error $_.Exception.Message
		$global:LastDPXCEError = $e
		return $e
    }# Catch
    Finally
    {
        if ($KeepResponse.isPresent)
        {
            Write-Verbose "Keeping full response in `$global:LastPlatformResponse."
            $global:LastPlatformResponse = $Response
        }
    }# Finally
}# function Invoke-DpxAPI 
#endregion
###########