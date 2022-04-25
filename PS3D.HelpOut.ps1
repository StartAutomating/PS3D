$PS3DLoaded = Get-Module PS3D
if (-not $PS3DLoaded) {
    $PS3DLoaded = Get-ChildItem -Recurse -Filter "*.psd1" | Where-Object Name -like 'PS3D*' | Import-Module -Name { $_.FullName } -Force -PassThru
}
if ($PS3DLoaded) {
    "::notice title=ModuleLoaded::PS3D Loaded" | Out-Host
} else {
    "::error:: PS3D not loaded" |Out-Host
}
if ($PS3DLoaded) {
    Save-MarkdownHelp -Module $PS3DLoaded.Name -PassThru |
        Add-Member NoteProperty CommitMessage "Updating docs" -Force -PassThru
}
