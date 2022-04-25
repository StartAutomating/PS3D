function Get-OpenSCAD
{
    <#
    .Synopsis
        Gets OpenSCAD designs
    .Description
        Gets information about OpenSCAD designs.
    .Example
        Get-OpenSCAD -ScadFilePath .\MyDesign.scad
    .Link
        Invoke-OpenSCAD
    #>
    param(
    # The path to an OpenSCAD file.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('Fullname')]
    [string]
    $ScadFilePath
    )
    
    begin {
        filter =>[OpenScad.Parameter] {
            $p = $_
            $type,$defaultValue =
                @(if ($p.Groups["BooleanValue"].Success) {
                    [switch], ($p.Groups["BooleanValue"].value -match $true)
                } elseif($p.Groups["NumberValue"].Success) {
                    [double], ($p.Groups["NumberValue"].value -as [double])
                } elseif ($p.Groups["StringValue"].Success) {
                    [string], $p.Groups["StringValue"].Value
                } elseif ($p.Groups["ListValue"].Success) {
                    [PSObject[]], $p.Groups["ListValue"].value -replace '\[', '@(' -replace '\]', ')'
                } else {
                    [PSObject], $null
                })

            if ($defaultValue -eq 'undef') {
                $defaultValue = $null
            }
            elseif ($p.Groups['ConstantValue'].Success) {
                $defaultValue = $null
            } 
            [PSCustomObject][Ordered]@{
                Name=$p.Groups["Name"].Value
                Type = $type                            
                DefaultValue=$defaultValue
            }
        }

        $openScadRegex = @{
    OpenSCAD_Include = [Regex]::new(@'
(?m)     # Set Multiline mode.  Then,
^include # match the literal 'include'
\s+      # and the obligitory whitespace.
\<(?<Include>[^\>]+)\>
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')


    OpenSCAD_Module = [Regex]::new(@'
(?m)                 # Set Multiline mode.  Then,
^module              # match the literal 'module'
\s+                  # and the obligitory whitespace.
(?<ModuleName>\w+)   # Then match and extract the <ModuleName>.
\s{0,}               # Then, there may be whitespace.
# The Module <ModuleParameters> are within ()
(?<Parameters>
\(                   # An open parenthesis
(?>                  # Followed by...
    [^\(\)]+|        # any number of non-parenthesis character OR
    \((?<Depth>)|    # an open parenthesis (in which case increment depth) OR
    \)(?<-Depth>)    # a closed parenthesis (in which case decrement depth)
)*(?(Depth)(?!))     # until depth is 0.
\)                   # followed by a closing parenthesis

)\s{0,}              # Then, there may be whitespace.
# The Module <ModuleDefinition> is Within {}
(?<Definition>
\{                   # An open {
(?>                  # Followed by...
    [^\{\}]+|        # any number of non-bracket character OR
    \{(?<Depth>)|    # an open curly bracket (in which case increment depth) OR
    \}(?<-Depth>)    # a closed curly bracket (in which case decrement depth)
)*?(?(Depth)(?!))    # until depth is 0.
\}                   # followed by a }

)
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')


    OpenSCAD_Function = [Regex]::new(@'
(?m)                                               # Set Multiline mode.  Then,
(?<Comments>//[\s.]{0,}?$(?>\r\n|\n)){0,}^function # match the literal 'function'
\s+                                                # and the obligitory whitespace.
(?<Name>\w+)                                       # Then match and extract the .Name
\s{0,}                                             # Then, there may be whitespace.
# The .Parameters are within ()
(?<Parameters>
\(                                                 # An open parenthesis
(?>                                                # Followed by...
    [^\(\)]+|                                      # any number of non-parenthesis character OR
    \((?<Depth>)|                                  # an open parenthesis (in which case increment depth) OR
    \)(?<-Depth>)                                  # a closed parenthesis (in which case decrement depth)
)*(?(Depth)(?!))                                   # until depth is 0.
\)                                                 # followed by a closing parenthesis

)\s{0,}                                            # Then, there may be whitespace.
\=\s{0,}                                           # Then, there may be whitespace.
(?:.|\s){0,}?(?=\z|;)
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')


    OpenSCAD_Customization = [Regex]::new(@'
(?m)^(?<Name>\w+)                        # Optional Whitespace
\s{0,}                                   # Optional Whitespace
\=\s{0,}                                 # Optional Whitespace
(?>
  (?<Value>(?<NumberValue>[\d\.]+)       # A numeric value
    |
    (?<BooleanValue>true|false)          # A boolean value
    |
    \"(?<StringValue>(?:.|\s)*?(?<!\\)") # A string value
    |
    (?<ListValue>(?<BalancedBrackets>
\[                                       # An open bracket
(?>                                      # Followed by...
    [^\[\]]+|                            # any number of non-bracket character OR
    \[(?<Depth>)|                        # an open bracket (in which case increment depth) OR
    \](?<-Depth>)                        # a closed bracket (in which case decrement depth)
)*(?(Depth)(?!))                         # until depth is 0.
\]                                       # followed by a closing bracket
)
)                                        # A List Value
))\s{0,}                                 # Optional Whitespace
\;                                       # Semicolon
(?<RestOfLine>.*$)
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')


    OpenSCAD_Use = [Regex]::new(@'
(?m) # Set Multiline mode.  Then,
^use # match the literal 'use'
\s+  # and the obligitory whitespace.
\<(?<Use>[^\>]+)\>
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')


    OpenSCAD_Parameter = [Regex]::new(@'
(?<=[\(\,])                                         # After a ( or a ,
\s{0,}                                              # Optional Whitespace
(?<Name>\w+)                                        # The Parameter Name
\s{0,}                                              # Optional Whitespace
# A literal = is used to determine if it Has a default value
(?<HasDefaultValue>=)?
# If there is a default value
(?(HasDefaultValue)(\s{0,}                          # Allow optional whitespace
# Match the value, which could be
(?>
  (?<Value>(?<ListValue>(?<BalancedBrackets>
\[                                                  # An open bracket
(?>                                                 # Followed by...
    [^\[\]]+|                                       # any number of non-bracket character OR
    \[(?<Depth>)|                                   # an open bracket (in which case increment depth) OR
    \](?<-Depth>)                                   # a closed bracket (in which case decrement depth)
)*(?(Depth)(?!))                                    # until depth is 0.
\]                                                  # followed by a closing bracket
)
)                                                   # A List Value
    |
    (?<NumberValue>[\d\.]+)                         # A number
    |
    (?<BooleanValue>true|false)                     # A boolean literal
    |
    (?<ConstantValue>\w+)                           # A constant value
    |
    \"                                              # A string
(?<StringValue>(?:.|\s)*?(?<!\\))"    |
    (?<Expression>(?<BalancedParenthesis>
\(                                                  # An open parenthesis
(?>                                                 # Followed by...
    [^\(\)]+|                                       # any number of non-parenthesis character OR
    \((?<Depth>)|                                   # an open parenthesis (in which case increment depth) OR
    \)(?<-Depth>)                                   # a closed parenthesis (in which case decrement depth)
)*(?(Depth)(?!))                                    # until depth is 0.
\)                                                  # followed by a closing parenthesis
)
)))))\s{0,}
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')


}

        
        
    }

    
    process {
        $resolvedScadFile = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($ScadFilePath)

        if (-not $resolvedScadFile) { return }

        $CustomizerFile = $resolvedScadFile -replace '\.scad$', '.json'

        $customizerPresets =
            if (Test-Path $CustomizerFile) {
                Get-content $CustomizerFile -Raw | 
                    ConvertFrom-Json | 
                    Where-Object ParameterSets | 
                    Select-Object -ExpandProperty ParameterSets            
            } else {$null }
        
        $openScadContent = Get-Content -Raw -LiteralPath $resolvedScadFile

        $allMatches = 
            @(foreach ($regex in $openScadRegex.GetEnumerator()) {
                if ($regex.Key -in 'OpenScad_Parameter') {
                    continue
                }
                foreach ($m in $regex.Value.Matches($openScadContent)) {                    
                    $m | 
                    Add-Member NoteProperty ExpressionName $regex.Key -Force -PassThru
                }
            }) | Sort-Object Index
        
        
        $uses      = @()
        $includes  = @()
        $modules   = @()
        $functions = @()
        $customizations = @()
        foreach ($match in $allMatches) {
            switch ($match.ExpressionName) {
                OpenSCAD_Use {
                    $uses += $match.Groups["Use"].Value
                }
                OpenSCAD_Include {
                    $includes += $match.Groups["Include"].Value
                }
                OpenSCAD_Module {
                    $commentMatchStart = $match.Index                                                            
                    $parameters = $openScadRegex.OpenSCAD_Parameter.Matches(($match.Groups["Parameters"].Value))

                    $scadInfo = [PSCustomObject]@{
                        ModuleName = $match.Groups["ModuleName"].Value
                        Parameters = @($parameters | =>[OpenSCAD.Parameter])
                        Definition = $match.Groups["Definition"]
                        FileName = "$($resolvedScadFile | Split-Path -Leaf)" -replace '\.scad$'
                        DirectoryName = "$($resolvedScadFile | Split-Path | Split-Path -Leaf)"
                        Match = $match
                        OpenScadPath = "$resolvedScadFile"
                    }
                    $modules += $scadInfo
                }
                OpenSCAD_Customization {
                    $customizations += $match |=>[OpenSCAD.Parameter]
                }
                OpenSCAD_Function {
                    $parameters = $openScadRegex.OpenSCAD_Parameter.Matches(($match.Groups["Parameters"].Value))
                    $scadInfo = [PSCustomObject]@{
                        ModuleName = $match.Groups["ModuleName"].Value
                        Parameters = @($parameters | =>[OpenSCAD.Parameter])
                        Definition = $match.Groups["Definition"]
                        FileName      = "$($resolvedScadFile | Split-Path -Leaf)" -replace '\.scad$'
                        DirectoryName = "$($resolvedScadFile | Split-Path | Split-Path -Leaf)"
                        Match = $match
                        OpenScadPath = "$resolvedScadFile"
                    }
                    $functions += $scadInfo
                }
            }
        }
        [PSCustomObject][Ordered]@{
            ScadFilePath   = "$resolvedScadFile"
            FileName       = "$($resolvedScadFile | Split-Path -Leaf)" -replace '\.scad$'
            DirectoryName  = "$($resolvedScadFile | Split-Path | Split-Path -Leaf)"
            Uses           = $uses
            Includes       = $includes
            Modules        = $modules
            Functions      = $functions
            Customizations = $customizations
            PresetNames    = if ($customizerPresets) { 
                $customizerPresets | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
            }
            Presets        = $customizerPresets
            PSTypeName     = 'OpenScad.FileInfo'
        }
        
    }   
}
