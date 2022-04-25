Write-FormatView -TypeName OpenSCAD.Output -Action {
    Write-FormatViewExpression -Text "Arguments"

    Write-FormatViewExpression -ScriptBlock { " $($_.OpenScadArguments -join ' ')" }

    Write-FormatViewExpression -Newline

    Write-FormatViewExpression -Text "Rendering Time" -if { $_.TotalRenderingTime }
    Write-FormatViewExpression -if { $_.TotalRenderingTime } -ScriptBlock { " $($_.TotalRenderingTime)" }
} -GroupByProperty OutputPath
