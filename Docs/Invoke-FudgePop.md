---
external help file: FudgePop-help.xml
Module Name: FudgePop
online version: 
schema: 2.0.0
---

# Invoke-FudgePop

## SYNOPSIS
Invokes a FudgePop Process

## SYNTAX

```
Invoke-FudgePop [-TestMode] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Invokes the FudgePop client process.
If Install-FudgePop has not yet been
executed, you will be prompted to do that first, in order to configure the
options required to support FudgePop. 
Otherwise, it will import the control 
XML file and process the instructions it provides.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Invoke-FudgePop
```

### -------------------------- EXAMPLE 2 --------------------------
```
Invoke-FudgePop -TestMode
```

### -------------------------- EXAMPLE 3 --------------------------
```
Invoke-FudgePop -Verbose
```

## PARAMETERS

### -TestMode
Force WhatIf and Verbose output

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

