#requires -Module PSDevOps
#requires -Module PS3D
Import-BuildStep -ModuleName PS3D
New-GitHubAction -Name "Out-PS3D" -Description 'Generate 3D Objects using PS3D and OpenSCAD' -Action PS3DAction -Icon box  -ActionOutput ([Ordered]@{
    PS3DScriptRuntime = [Ordered]@{
        description = "The time it took the .PS3DScript parameter to run"
        value = '${{steps.PS3DAction.outputs.PS3DScriptRuntime}}'
    }
    PS3DPS1Runtime = [Ordered]@{
        description = "The time it took all .PS3D.ps1 files to run"
        value = '${{steps.PS3DAction.outputs.PS3DPS1Runtime}}'
    }
    PS3DPS1Files = [Ordered]@{
        description = "The .PS3D.ps1 files that were run (separated by semicolons)"
        value = '${{steps.PS3DAction.outputs.PS3DPS1Files}}'
    }
    PS3DPS1Count = [Ordered]@{
        description = "The number of .PS3D.ps1 files that were run"
        value = '${{steps.PS3DAction.outputs.PS3DPS1Count}}'
    }
}) |
    Set-Content .\action.yml -Encoding UTF8 -PassThru
