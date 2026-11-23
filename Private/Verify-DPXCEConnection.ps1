###########
#region ### Verify-DPXCEConnection # Check to ensure you are connected to the instance before proceeding.
###########
function global:Verify-DPXCEConnection
{
    <#
    .SYNOPSIS
    This function verifies you have an active connection to a Delinea Platform instance.

    .DESCRIPTION
    This function verifies you have an active connection to a Delinea Platform instance. It checks for the existance of a $DPXCEConnection 
    variable to first check if a connection has been made, then it makes a Security/whoami RestAPI call to ensure the connection is active and valid.
    This function will store a date any only check if the last attempt was made more than 5 minutes ago. If the last verify attempt occured
    less than 5 minutes ago, the check is skipped and a valid connection is assumed. This is done to prevent an overbundence of whoami calls to the 
    Delinea Platform.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function only throws an error if there is a problem with the connection.

    .EXAMPLE
    C:\PS> Verify-DPXCEConnection
    This function will not return anything if there is a valid connection. It will throw an exception if there is no connection, or an 
    expired connection.
    #>

    if ($DPXCEConnection -eq $null)
    {
        throw ("There is no existing `$DPXCEConnection. Please use Connect-DpxTenant to connect to your Delinea Platform Tenant. Exiting.")
    }
    else
    {
        Try
        {
            # check to see if Lastwhoami is available
            if ($global:LastMyUserInfocheck)
            {
                # if it is, check to see if the current time is less than 5 minute from its previous whoami check
                if ($(Get-Date).AddMinutes(-5) -lt $global:LastMyUserInfocheck)
                {
                    # if it has been less than 5 minutes, assume we're still connected
                    return
                }
            }# if ($global:LastMyUserInfocheck)
            
            $uri = ("https://{0}/identity/api/UserMgmt/GetUserInfo" -f $global:DPXCEConnection.PodFqdn)

            # calling Security/whoami
            $UserInfoResponse = Invoke-RestMethod -Method Post -Uri $uri @global:DPXCESessionInformation
           
            # if the response was successful
            if ($UserInfoResponse.Success)
            {
                # setting the last whoami check to reduce frequent whoami calls
                $global:LastMyUserInfocheck = (Get-Date)
                return
            }
            else
            {
                throw ("There is no active, valid Platform Tenant connection. Please use Connect-DpxTenant to re-connect to your Delinea Platform Tenant. Exiting.")
            }
        }# Try
        Catch
        {
            throw ("There is no active, valid Platform Tenant connection. Please use Connect-DpxTenant to re-connect to your Delinea Platform Tenant. Exiting.")
        }
    }# else
}# function global:Verify-DPXCEConnection
#endregion
###########