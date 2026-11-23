#######################################
#region ### MAIN ######################
#######################################

# version check
if ($PSVersionTable.PSVersion.ToString() -lt 7.6)
{
	Write-Error "PowerShell version 7.6+ required."
	Exit 1
}

# getting directories, except Pester, Wrappers or Config
$Directories = Get-ChildItem -Recurse -Directory | Where-Object -Property Name -notmatch "Pester"

# getting current Directory
$CurrentDirectory = Get-Location | Select-Object -ExpandProperty Path

# ArrayList to hold all our scripts
$DPXCEScripts = [System.Collections.ArrayList]::new()

# ArrayList to hold ScriptBlocks
$DPXCEScriptBlocks = [System.Collections.ArrayList]::new()

# for each directory we found
foreach ($directory in $Directories)
{
	# get the items in that directory
	$foldercontents = Get-ChildItem -Path $directory

	# use regex to only match .ps1 scripts that do NOT start with an underscore (_)
	$folderscripts = $foldercontents | Where-Object -Property FullName -match '^.*\\(?!_)([a-zA-Z]+\-?[a-zA-Z]+\.ps1)$'

	# add the short folder name as an extra property
	$folderscripts | Add-Member -MemberType NoteProperty -Name ScriptType -Value ($directory.FullName -replace "^$([Regex]::Escape($CurrentDirectory))\\(.*)$", '$1')
	
	# add it to our script ArrayList
	[void]$DPXCEScripts.AddRange(@($folderscripts))
}# foreach ($directory in $Directories)

# for each script we found
foreach ($script in $DPXCEScripts)
{
	# get the contents of the script
    $scriptcontents = Get-Content $script.FullName -Raw

    # new temp object for the ScriptBlock ArrayList
    $obj = [PSCustomObject]::new()

    # getting the scriptblock
    $scriptblock = ([ScriptBlock]::Create(($scriptcontents)))

    # setting properties
    $obj | Add-Member -MemberType NoteProperty -Name Name        -Value $script.Name
	$obj | Add-Member -MemberType NoteProperty -Name Type        -Value $script.ScriptType
    $obj | Add-Member -MemberType NoteProperty -Name Path        -Value $script.FullName
    $obj | Add-Member -MemberType NoteProperty -Name ScriptBlock -Value $scriptblock

    # adding our temp object to our ArrayList
    [void]$DPXCEScriptBlocks.Add($obj)

    # and dot source it
    . $scriptblock
}# foreach ($script in $DPXCEScripts)

# setting our ScriptBlock ArrayList to global
$global:DPXCEScriptBlocks = $DPXCEScriptBlocks

#######################################
#endregion ############################
#######################################
