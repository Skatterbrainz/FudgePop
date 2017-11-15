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
Get-FudgePopInventory [[-ComputerName] <String[]>] [[-FilePath] <String>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Create an HTML inventory report of hardware, software and operating system
for the local computer, or a remote computer.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-FudgePopInventory -Computer WS01,WS02 -FilePath "c:\users\dave\documents"
```

## PARAMETERS

### -ComputerName
\[string-array\]\[optional\] Name of one or more computers to query. 
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
\[string\]\[optional\] Path and filename for the inventory report.
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

## INPUTS

## OUTPUTS

## NOTES
1.0.8 - 11/14/2017 - David Stein

## RELATED LINKS

