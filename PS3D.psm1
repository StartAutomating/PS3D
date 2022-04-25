foreach ($file in Get-ChildItem -Path $PSScriptRoot -Recurse -Filter *-*.ps1) {
    . $file.Fullname
}