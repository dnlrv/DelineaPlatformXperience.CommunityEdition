###########
#region ### global:Invoke-DpxAPI # CMDLETDESCRIPTION : Invoke any RestAPI endpoint in a connected Delinea Platform instance :
###########
function global:Invoke-DpxAPI
{
    <#
    .SYNOPSIS
    This function will provide an easy way to interact with any RestAPI endpoint to a connected Delinea Platform instance.

    .DESCRIPTION
    This function will provide an easy way to interact with any RestAPI endpoint in a Delinea Platform instance. This function requires an existing, valid $DPXCEConnection
    to exist.

    This function has 2 forms, depending on which endpoints need to be accessed:

      - If the endpoint is a pure delinea.app endpoint, like myurl.delinea.app/identity/api/UserMgmt/GetUserInfo, then the default is just to use
        this cmdlet with the -APICall parameter and type in the endpoint uri after the *.deliena.app portion.
        - For example, Invoke-DpxAPI -APICall identity/api/UserMgmt/GetUserInfo
      - If the endpoint is a Secret Server endpoint, like api/v1/folders, then the full uri needs to be typed out using the override parameter.
        - For example, Invoke-DpxAPI -OverrideUriAPI myurl.secretservercloud.com/api/v1/folders

    .PARAMETER APICall
    Specify the RestAPI endpoint to target. For example "identity/api/UserMgmt/GetUserInfo" or "inventory/api/types/computer".

    .PARAMETER OverrideUriAPI
    Specify the full uri to override, primarily used for Secret Server endpoints.

    .PARAMETER Body
    Specify the JSON body payload for the RestAPI endpoint.

    .PARAMETER Method
    Specify the Method to use with this call. Default is POST.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs as PSCustomObject with the requested data if the RestAPI call was successful.

    .EXAMPLE
    C:\PS> Invoke-DpxAPI -APICall identity/api/UserMgmt/GetUserInfo
    This will attempt to reach the identity/api/UserMgmt/GetUserInfo RestAPI endpoint in the currently connected Platform instance. If there is a 
    valid connection, information about the connected user will be returned as output.

    .EXAMPLE
    C:\PS> Invoke-DpxAPI -OverrideUriAPI myurl.secretservercloud.com/api/v1/folders -Body $folderjson
    This will attempt to reach the Secret Server Folder RestAPI endpoint in the currently connected Platform instance. If there is a 
    valid connection, performs a POST action based on what the $folderjson body payload contains.

    .EXAMPLE
    C:\US> Invoke-DpxAPI -OverrideUriAPI myurl.secretservercloud.com/api/v1/users/current -Method GET
    This will attempt to reach the Secret Server Folder RestAPI endpoint in the currently connected Platform instance. If there is a 
    valid connection, performs a GET action.
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    param
    (
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Specify the API call to make.", ParameterSetName = "Default")]
        [System.String]$APICall,

        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Specify the API call to make. Overrides the domain name completely. Mostly used for Secret Server endpoints.", ParameterSetName = "Override")]
        [System.String]$OverrideUriAPI,

        [Parameter(Position = 1, Mandatory = $false, HelpMessage = "Specify the JSON Body payload.")]
        [System.String]$Body,

        [Parameter(Mandatory = $false, HelpMessage = "Method to use on the Invoke-WebRequest.")]
        [ValidateSet("GET","POST","PATCH","OPTIONS","PUT")]
        [System.String]$Method = "POST",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the API call to make.", ParameterSetName = "Default")]
        [Parameter(Mandatory = $false, HelpMessage = "Specify the API call to make.", ParameterSetName = "Override")]
        [Switch]$KeepResponse

    )

    # verifying an active Platform connection
    Verify-DPXCEConnection

    if ($PSCmdlet.ParameterSetName -eq "Override")
    {
        $uri = $OverrideUriAPI
        # if URL provided doesn't have "https://" in front, add it.
        if ($uri.ToLower().Substring(0,8) -ne "https://")
        {
            $uri = ("https://{0}" -f $uri)
        }
    }# if ($PSCmdlet.ParameterSetName -eq "Override")
    else 
    {
        # setting the url based on our DPXCEConnection information
        $uri = ("https://{0}/{1}" -f $global:DPXCEConnection.PodFqdn, $APICall)
    }

    # Try
    Try
    {
        Write-Verbose ("Uri=[{0}]" -f $uri)

        # if the -Body parameter was used
        if ($PSBoundParameters.ContainsKey('Body'))
        {
            Write-Verbose ("Body=[{0}]" -f $Body)
            # making the call using our a Splat version of our connection
            $Response = Invoke-RestMethod -Method $Method -Uri $uri -Body $Body @global:DPXCESessionInformation
        }
        else # otherwise
        {
            # making the call using our a Splat version of our connection
            $Response = Invoke-RestMethod -Method $Method -Uri $uri @global:DPXCESessionInformation
        }

        # if the response was successful, some Platform endpoints have a Response property as part of the response
        if ($Response.Success)
        {
            if ($Response.Result -ne $null)
            {
                # return the results
                return $Response.Result
            }
            if ($Response.records -ne $null) # this is for Secret Server responses
            {
                return $Response.records
            }

            return $Response
        }# if ($Response.Success)
        else
        {
            # otherwise return the response
            return $Response
        }
    }# Try
    Catch
    {
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
            $global:LastPlatformResponse = $Response
        }
    }# Finally
}# function global:Invoke-DpxAPI 
#endregion
###########