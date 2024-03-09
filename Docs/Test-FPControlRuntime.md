---
external help file: FudgePop-help.xml
Module Name: FudgePop
online version:
schema: 2.0.0
---

# Test-FPControlRuntime

## SYNOPSIS
Confirm Task Execution Time

## SYNTAX

```
Test-FPControlRuntime [-RunTime] <String> [[-Key] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Return TRUE if a task runtime is active

## EXAMPLES

### EXAMPLE 1
```
Test-FPControlRuntime -RunTime "now"
```

### EXAMPLE 2
```
Test-FPControlRuntime -RunTime "11/12/2017 10:05:00 PM"
```

### EXAMPLE 3
```
Test-FPControlRuntime -RunTime "daily" -Key "TestValue"
```

## PARAMETERS

### -RunTime
Date Value, or 'now' or 'daily'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Key
Label to map to Registry for get/set operations

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
