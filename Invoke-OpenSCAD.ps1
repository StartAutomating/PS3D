function Invoke-OpenScad
{
    <#
    .Synopsis
        Invokes OpenScad
    .Description
        Invokes OpenSCAD
    .Example
        Invoke-OpenSCAD -ScadFilePath .\MyDesign.scad
    .Example
        Invoke-OpenSCAD -ScadFilePath .\MyCustomizableDesign.scad -Parameter @{ThingWidth=10}
    .Example
        Invoke-OpenSCAD -ScadFilePath .\MyCustomizableDesign.scad -CustomizerPreset MyPreset
    .LINK
        Get-OpenSCAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
    # The path to an OpenSCAD file.
    [Parameter(Mandatory,ParameterSetName='ScadFilePath',ValueFromPipelineByPropertyName,Position=0)]
    [alias('FullName', 'InputPath')]
    [string]
    $ScadFilePath,

    # A dictionary of parameters
    [Parameter(ValueFromPipelineByPropertyName)]
    [Collections.IDictionary]
    [Alias('Parameters')]
    $Parameter,

    # A customizer parameter file.  
    # If no file is provided, and a -CustomizerPreset is used, then the -ScadFilePath.json will be used.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('CustomFile')]
    [string[]]    
    $CustomizerFile,

    # The name of one or more presets within a -CustomizerFile.
    # One output will be generated per preset, and will have the name FileName-Preset.stl
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('CustomPreset','CustomPresets','Preset','PresetName','PresetNames')]
    [string[]]
    $CustomizerPreset,

    # The output path.  If not provided, this will be the -ScadFilePath, with the extension changed to .stl.
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $OutputPath,

    # The path to the OpenScad command.  This parameter is not required if openscad is in $env:Path.
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $OpenScadCommand,

    # If set, will run as a background job
    [Parameter(ValueFromPipelineByPropertyName)]
    [switch]
    $AsJob,

    # Any remaining arguments to OpenSCAD.
    [Parameter(ValueFromPipelineByPropertyName,ValueFromRemainingArguments)]
    [Alias('OpenSCADArguments', 'OpenScadArgs')]
    [string[]]
    $OpenScadArgument,

    # Any parameters to OpenSCAD.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('OpenScadParameters', 'OpenScadParam', 'OpenScadParams')]
    [Collections.IDictionary]
    $OpenScadParameter
    )

    begin {
        function =>[OpenScad.Output] {
            param(
            [string[]]
            $OpenSCADArguments,

            [string]
            $OutputPath
            )
            begin {
                $outputData = [Ordered]@{PSTypeName='OpenScad.Output';OutputPath  =$OutputPath; OpenSCADArguments =$OpenSCADArguments; OpenSCADLog = @()}
                $fixCasing  = [Regex]::new('\s\p{L}')
            }
            process {
                $line =  $_
                $outputData.OpenSCADLog += $line
                if ($line -match '([\w\s]+):\s+([\w\.\:]+)') {
                    $key, $value = $matches.1, $matches.2
                    $key = $key -replace '^\s+'
                    $key = $fixCasing.Replace($key, {
                        $args[0].ToString().Trim().ToUpper()
                    })
                    $outputData[$key] = 
                        if ($value -as [int]) {
                            $value -as [int]
                        } elseif ($value -in 'yes', 'no') {
                            $value -replace 'yes', 'true' -replace 'no' -as [bool]
                        } elseif ($value -as [Timespan]) {
                            $value -as [timespan]
                        } else {
                            $value
                        }
                }
            }
            end {                
                [PSCustomObject]$outputData
            }
        }
    }

    process {
        if ($AsJob) {
            $PSBoundParameters.Remove('AsJob')
            $myDefinition = '' + {
param([Collections.IDictionary]$params)
} + [ScriptBlock]::Create("function $($MyInvocation.MyCommand.Name) {
$($MyInvocation.MyCommand.ScriptBlock)                
}

$($MyInvocation.MyCommand.Name) @params
")
            Start-Job -ScriptBlock $myDefinition -ArgumentList $PSBoundParameters -Name "$ScadFilePath"
            return
        }

        if (-not $OpenScadCommand) {
            $OpenScadCommand = 'openscad'
        }

        $openScadCmd = $ExecutionContext.SessionState.InvokeCommand.GetCommand($openScadCommand, 'Application')
        if (-not $openScadCmd) {
            if ($env:ProgramFiles) { 
                $openScadCmd = 
                    $ExecutionContext.SessionState.InvokeCommand.GetCommand(
                        ($env:ProgramFiles,'OpenScad', 'openscad.com' -join [io.path]::DirectorySeparatorChar),
                        'Application'
                    )
            }
            if (-not $openScadCmd) {
                Write-Error "OpenScad not found"
                return
            }            
        }
        
        $resolvedScadPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($ScadFilePath)
        if (-not $resolvedScadPath) { return }
        $scadFileName = ($resolvedScadPath | Split-Path -Leaf) -replace '\.scad$'
        $ScadOutPath = 
            if ($PSBoundParameters['OutputPath']) {
                $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
            } else {
                $resolvedScadPath -replace '\.scad$', '.stl'
            }
        
        $scadContent = @(Get-content $resolvedScadPath)

        $scadParamPath = 
            if ($env:windir -and $env:TEMP) {
                Join-Path $env:TEMP "$scadFileName.json"
            } else {
                Join-Path /tmp "$scadFileName.json"
            }

        
        $openScadArgs = @(
        "$resolvedScadPath"
        "-o"
        )


        if ($OpenScadParameter) {
            $OpenScadArgument += 
                @(foreach ($param in $OpenScadParameter.GetEnumerator()) {
                    $param.Key -replace '^-{0,}', '--'
                    $param.Value
                })
        }

        if ($CustomizerPreset) {
            if (-not $CustomizerFile) {
                $CustomizerFile = $resolvedScadPath -replace '\.scad$', '.json'
            }

            if (Test-Path $CustomizerFile) {
                $customizerPresetFile = Get-Content $CustomizerFile -Raw | ConvertFrom-Json
            }

            foreach ($pre in $CustomizerPreset) {
                $outPath = 
                    if ($PSBoundParameters['OutputPath']) {
                        $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(($OutputPath -replace '\.(.+)$', "-$pre.`$1"))
                    } else {
                        $resolvedScadPath -replace '\.scad$', "-$pre.stl"
                    }
                $preArgs = @() + $openScadArgs + @(
                    $outPath
                    "-p"
                    $CustomizerFile
                    "-P"
                    $pre
                )
                 & $openScadCmd @preArgs @OpenScadArgument *>&1 | =>[OpenScad.Output] -OpenSCADArguments $preArgs -OutputPath $outPath                
            }

            
        } else {
            $openScadArgs += @(                
                "$scadOutPath"
                if ($Parameter) {
                    # '-D'
                    $paramsFileContent = [Ordered]@{}
                    foreach ($p in $Parameter.GetEnumerator()) {
                        $paramMatch = "(?<Name>$($p.Key))\s?=.*$"
                        $matchingLine = $($scadContent -match $paramMatch)
                        if (-not $matchingLine) {
                            Write-Warning "Parameter '$($p.Key)' not found in '$ScadFilePath'"
                            continue
                        }

                        $null = $matchingLine -match $paramMatch
                        $paramName = $matches.Name
                        $paramValue = $p.Value

                        $paramsFileContent[$paramName] = $p.Value                    
                    }
                
                    @{parameterSets=@{Parameters=$paramsFileContent}} | 
                        ConvertTo-Json -Depth 10 |
                        Set-Content -Path $scadParamPath

                    '-p'
                    "$scadParamPath"
                    "-P"
                    'Parameters'
                }
            )

            Write-Verbose "$OpenScadCmd $($openScadArgs -join ' ')"

            & $OpenScadCmd @OpenScadArgs @OpenScadArgument *>&1 | =>[OpenScad.Output] -OpenSCADArguments $openScadArgs -OutputPath "$scadOutPath"

            if (Test-Path $scadParamPath) {
                Remove-Item $scadParamPath
            }
        } 
    }
}
