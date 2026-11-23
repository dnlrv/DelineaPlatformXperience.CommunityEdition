# DPXCE.psm1 root module

# get the path of the current module directory
$ClassesPath = Join-Path -Path $PSScriptRoot -ChildPath "Classes"
$PublicPath  = Join-Path -Path $PSScriptRoot -ChildPath "Public"
$PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath "Private"
$ThisPath    = Join-Path -Path $PSScriptRoot -ChildPath "This"

# dot-source all Classes first
Get-ChildItem -Path $ClassesPath -Filter *.ps1 | ForEach-Object { . $_.FullName }

# dot-source all Private (Helper) functions first
Get-ChildItem -Path $PrivatePath -Filter *.ps1 | ForEach-Object { . $_.FullName }

# dot-source all Public (User-facing) functions
Get-ChildItem -Path $PublicPath -Filter *.ps1 | ForEach-Object { . $_.FullName }

# dot-source all This- functions
Get-ChildItem -Path $ThisPath -Filter *.ps1 | ForEach-Object { . $_.FullName }

# setting PublicFunctions with the name of all the functions in the Public folder so I don't need to keep updating the manifest
$PublicFunctions  = Get-ChildItem -Path $PublicPath -Filter *.ps1  | ForEach-Object { $_.BaseName }
$ThisFunctions    = Get-ChildItem -Path $ThisPath -Filter *.ps1    | ForEach-Object { $_.BaseName }

# export all the functions found in the Public and This folder
Export-ModuleMember -Function $PublicFunctions
Export-ModuleMember -Function $ThisFunctions