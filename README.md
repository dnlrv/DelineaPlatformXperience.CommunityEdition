# DelineaPlatformXperience.CommunityEdition (DPXCE) (unofficial Delinea Platform PowerShell Module)

A variety of functions to make working with Delinea's Platform even easier.

There are three ways to install/use DPXCE (choose one): 
- the "Cloud Grab" method 
- the "Local Loader" method
- the traditional PowerShell module method.

**This module requires PowerShell version 7.6+ or greater.**

## DelineaPlatformXperience.CommunityEdition (DPXCE) (Cloud Grab)

The Cloud Grab method invokes all the scripts directly from this GitHub repo. The biggest benefit is that any updates/fixes/enhancements to DPXCE will reflect on the next Cloud Grab, no local install is needed. The module lives completely in session memory and will disappear after closing the PowerShell session.

To get started, copy the snippet below and paste it directly into a PowerShell (Run-As Administrator not needed) window and run it. This effectively invokes every script from this GitHub repo directly as a web request and dot sources it into your current PowerShell session.

```PowerShell
$DPXCE = ([ScriptBlock]::Create(((Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dnlrv/DelineaPlatformXperience.CommunityEdition/main/DPXCE.ps1').Content))); . $DPXCE
```

## DelineaPlatformXperience.CommunityEdition (DPXCE) (Local Loader)

The Local Loader method involves downloading the contents of the repo to any folder and using the module from there. The benefit here is that this method will work from any folder, not just the official PowerShell module folders. This is a local, but portable install of this module.

To ge started, download the repo and move it into a desired folder. Then open a PowerShell session and navigate to that folder. Then run the following:

```PowerShell
. (([ScriptBlock]::Create((Get-Content .\DPXCE_local.ps1 -Raw))))
```

# DelineaPlatformXperience.CommunityEdition (DPXCE) (Traditional Module)

The Traditional Module method is downloading the module and installing it into a Microsoft approved locate for PowerShell modules just like any other PowerShell module.

For example, to make this module available system-wide, place the contents of this repo in a folder located at `C:\Program Files\PowerShell\7\Modules\DPXCE`.

The module should be available with the `Import-Module DPXCE` command from that point forward.

## Disclaimer

The contents (scripts, documentation, examples) included in this repository are not supported under any Delinea standard support program, agreement, or service. The code is provided AS IS without warranty of any kind. Delinea further disclaims all implied warranties, including, without limitation, any implied warranties of merchantability or fitness for a particular purpose. The entire risk arising out of the code and content's use or performance remains with you. In no event shall Delinea, its authors, or anyone else involved in the creation, production, or delivery of the content be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the code or content, even if Delinea has been advised of the possibility of such damages.

## Requirements

This module requires PowerShell version 7.6 at minimum. Also outbound internet access is needed since you're trying to communicate with the Platform. Proxy support is something planned in the future.

## How to use

Once ready by one of the three methods mentioned above, all public functions have standard PowerShell help files associated with them. So you can use `Get-Help Connect-DpxTenant` to get the help file for that cmdlet.

First you need to connect to your tenant with `Connect-DpxTenant`. Here is an example:

```PowerShell
Connect-DpxTenant -Url myurl.delinea.app -User mycloudadmin@domain.com
```

*Federated Users* - a small popup will occur that will have you log into your Federated IdP. Once you complete authentication, the pop should close and you should be back in the PowerShell session.

*Non-Federated Users* - You will be prompted for a password and whatever MFA challenge is associated with that login.

### Underscore (_) scripts

Any `.ps1` that starts with an underscore (_) will be ignored by the module processing. This would be useful in the event you need to temporarily disable a script without removing it.

## Once Connected

If you get output from the `Connect-DpxTenant` cmdlet, you're connected and will remain connected for however long your tenant allows you to stay connected. All further cmdlets using this module from this point forward will use your credentials as if you were logged into the GUI tenant.

Use `Get-DPXCECommands` to display all cmdlets related to this module.

Some cmdlets have additional methods with the custom class objects they return. See the help file for each cmdlet for more details.

## How to update

Updating depends on what method you used:

- Cloud Grab - just run the same Cloud Grab snippet again.
- Local Loader/Traditional Module - Repeat the initial steps.
