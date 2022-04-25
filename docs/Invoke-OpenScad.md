
Invoke-OpenScad
---------------
### Synopsis
Invokes OpenScad

---
### Description

Invokes OpenSCAD

---
### Related Links
* [](Get-OpenSCAD.md)
---
### Examples
#### EXAMPLE 1
```PowerShell
Invoke-OpenSCAD -ScadFilePath .\MyDesign.scad
```

#### EXAMPLE 2
```PowerShell
Invoke-OpenSCAD -ScadFilePath .\MyCustomizableDesign.scad -Parameter @{ThingWidth=10}
```

#### EXAMPLE 3
```PowerShell
Invoke-OpenSCAD -ScadFilePath .\MyCustomizableDesign.scad -CustomizerPreset MyPreset
```

---
### Parameters
#### **ScadFilePath**

The path to an OpenSCAD file.



|Type          |Requried|Postion|PipelineInput        |
|--------------|--------|-------|---------------------|
|```[String]```|true    |1      |true (ByPropertyName)|
---
#### **Parameter**

A dictionary of parameters



|Type               |Requried|Postion|PipelineInput        |
|-------------------|--------|-------|---------------------|
|```[IDictionary]```|false   |named  |true (ByPropertyName)|
---
#### **CustomizerFile**

A customizer parameter file.  
If no file is provided, and a -CustomizerPreset is used, then the -ScadFilePath.json will be used.



|Type            |Requried|Postion|PipelineInput        |
|----------------|--------|-------|---------------------|
|```[String[]]```|false   |named  |true (ByPropertyName)|
---
#### **CustomizerPreset**

The name of one or more presets within a -CustomizerFile.
One output will be generated per preset, and will have the name FileName-Preset.stl



|Type            |Requried|Postion|PipelineInput        |
|----------------|--------|-------|---------------------|
|```[String[]]```|false   |named  |true (ByPropertyName)|
---
#### **OutputPath**

The output path.  If not provided, this will be the -ScadFilePath, with the extension changed to .stl.



|Type          |Requried|Postion|PipelineInput        |
|--------------|--------|-------|---------------------|
|```[String]```|false   |named  |true (ByPropertyName)|
---
#### **OpenScadCommand**

The path to the OpenScad command.  This parameter is not required if openscad is in $env:Path.



|Type          |Requried|Postion|PipelineInput        |
|--------------|--------|-------|---------------------|
|```[String]```|false   |named  |true (ByPropertyName)|
---
#### **AsJob**

If set, will run as a background job



|Type          |Requried|Postion|PipelineInput        |
|--------------|--------|-------|---------------------|
|```[Switch]```|false   |named  |true (ByPropertyName)|
---
#### **OpenScadArgument**

Any remaining arguments to OpenSCAD.



|Type            |Requried|Postion|PipelineInput        |
|----------------|--------|-------|---------------------|
|```[String[]]```|false   |named  |true (ByPropertyName)|
---
#### **OpenScadParameter**

Any parameters to OpenSCAD.



|Type               |Requried|Postion|PipelineInput        |
|-------------------|--------|-------|---------------------|
|```[IDictionary]```|false   |named  |true (ByPropertyName)|
---
### Syntax
```PowerShell
Invoke-OpenScad [-ScadFilePath] <String> [-Parameter <IDictionary>] [-CustomizerFile <String[]>] [-CustomizerPreset <String[]>] [-OutputPath <String>] [-OpenScadCommand <String>] [-AsJob] [-OpenScadArgument <String[]>] [-OpenScadParameter <IDictionary>] [<CommonParameters>]
```
---


