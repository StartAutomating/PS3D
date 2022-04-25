@{
    Description = '3D Printing Tools for PowerShell'
    ModuleVersion = '0.1'
    RootModule    = 'PS3D.psm1'
    Guid = 'f9935c9c-8d5b-4fb0-a51e-117a3a5044a9'
    Copyright = '2022 Start-Automating'
    Author = 'James Brundage'
    CompanyName='Start-Automating'
    FormatsToProcess = 'PS3D.format.ps1xml'
    PrivateData = @{
        PSData = @{
            ProjectURI = 'https://github.com/StartAutomating/PS3D'
            LicenseURI = 'https://github.com/StartAutomating/PS3D/blob/main/LICENSE'

            Tags = 'OpenSCAD', 'PowerShell', '3DPrinting'
            ReleaseNotes = @'
### 0.1
Initial Release
* Get-OpenSCAD (#2)
* Invoke-OpenSCAD (#1)
* Auto-documentation (#3)
* Auto-formatting (#5)
* Auto-publish (#4)
* Formatting for OpenSCAD.Output (#9)
---
'@
        }
    }
}
