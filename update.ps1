

$pwd = pwd
$scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent

if ("$pwd" -ne "$scriptDir") {
    echo "Please run this from the addon's directory."
    exit 1
}

$version = git describe --tags

echo "Publishing $version"

$prompt = "OK? [y/n]"
$confirmation = Read-Host $prompt
while ($confirmation -ne "y") {
    if ($confirmation -eq "n") {exit}
    $confirmation = Read-Host $prompt
}

& "C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\bin\gmad.exe" create -folder . -out ph_addon.gma
if ($?) {
    echo OK
    # & "C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\bin\gmpublish.exe" create -addon ph_addon.gma -icon logos\ph_logo.jpg
    & "C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\bin\gmpublish.exe" update -addon ph_addon.gma -id "1585255351" -changes "$version"
}
