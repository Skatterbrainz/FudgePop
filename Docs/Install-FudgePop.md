---
external help file: FudgePop-help.xml
Module Name: FudgePop
online version: 
schema: 2.0.0
---

# Install-FudgePop

## SYNOPSIS
Configure FudgePop options and Scheduled Task

## SYNTAX

```
Install-FudgePop [-UseDefaults] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Configures FudgePop options, including source control XML file path,
and Scheduled Task options.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Install-FudgePop -UseDefaults
```

## PARAMETERS

### -UseDefaults
Applies default settings and initializes the
scheduled client task at a 1 hour interval. 
The default control XML
file path is the URI to the control.xml on the project Github site.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
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

## INPUTS

## OUTPUTS

## NOTES
1.0.15 - 12/27/2017 - David Stein

## RELATED LINKS

