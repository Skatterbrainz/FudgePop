---
external help file: FudgePop-help.xml
Module Name: FudgePop
online version:
schema: 2.0.0
---

# Get-FudgePopInventory

## SYNOPSIS
Create HTML inventory report of computer

## SYNTAX

```
Get-FudgePopInventory [[-ComputerName] <String[]>] [[-FilePath] <String>] [[-StyleSheet] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create an HTML inventory report of hardware, software and operating system
for the local computer, or a remote computer.

## EXAMPLES

### EXAMPLE 1
```
Get-FudgePopInventory -Computer WS01,WS02 -FilePath "c:\users\dave\documents"
```

## PARAMETERS

### -ComputerName
Name of one or more computers to query. 
A separate
report file is generated for each computer. 
Default value is local computer.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath
Path and filename for the inventory report.
If not specified, the default is $env:TEMP\computername_inventory.htm

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: "$($env:USERPROFILE)\Documents"
Accept pipeline input: False
Accept wildcard characters: False
```

### -StyleSheet
Path and filename for CSS stylesheet template.
Default uses an internal "default.css" within the module structure

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
