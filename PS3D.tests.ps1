describe PS3D {
    BeforeAll {
        if ($PSVersionTable.Platform -eq 'Unix') {
            $openScadInPath =  $ExecutionContext.SessionState.InvokeCommand.GetCommand('openscad', 'Application')
            if (-not $openScadInPath -and $env:GITHUB_WORKFLOW) {
                "::group::Installing OpenSCAD" | Out-Host
                cd $GITHUB_WORKSPACE
                wget https://files.openscad.org/OpenSCAD-2021.01-x86_64.AppImage
                sudo mv OpenSCAD-2021.01*-x86_64.AppImage /usr/local/bin/openscad
                sudo chmod +x /usr/local/bin/openscad
                "::endgroup::" | Out-Host
            }
        }
        
        
        $parameterizableCube = @"
X = 30;
Y = 20;
Z = 10;

cube([X,Y,Z]);
"@

        $parameterizableCube | Set-Content .\CubeTest.scad

        [Ordered]@{
            parameterSets = [Ordered]@{
                "1cm" = [Ordered]@{
                    X = 10
                    Y = 10
                    Z = 10
                }
                "2cm" = [Ordered]@{
                    X = 20
                    Y = 20
                    Z = 20
                }
                "3cm-2cm-1cm" = [Ordered]@{
                    X = 30
                    Y = 20
                    Z = 10
                }
            }
        } | ConvertTo-Json -Depth 100 | Set-Content .\CubeTest.json
    }
    context Get-OpenSCAD {
        it 'Can get information about an OpenSCAD file' {
            $openScadInfo = Get-OpenScad -ScadFilePath .\CubeTest.scad
            $openScadInfo.PresetNames | Should -Match '^\dcm'
        }
    }

    context Invoke-OpenSCAD {
        it 'Can print OpenSCAD files' {
            $osInvokeInfo = Invoke-OpenSCAD -ScadFilePath .\CubeTest.scad
            $osInvokeInfo.GeometriesInCache | Should -be 1
            $osInvokeInfo.Facets | Should -be 6
        }

        it 'Can print all of the presets associated with an OpenSCAD file' {
            $openScadInfo   = Get-OpenScad -ScadFilePath .\CubeTest.scad
            $openScadOutput = $openScadInfo | Invoke-OpenSCAD
            
            $openScadOutput.Count | Should -be $openScadInfo.PresetNames.Count
            $openScadOutput.GeometriesInCache | Should -be @(@(1) * $openScadInfo.PresetNames.Count)
            $openScadOutput.Facets | Should -be @(@(6) * $openScadInfo.PresetNames.Count)
        }
    }
    AfterAll {
        dir CubeTest* | Remove-Item
    }
}
