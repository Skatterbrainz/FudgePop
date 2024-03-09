---
external help file: FudgePop-help.xml
Module Name: FudgePop
online version:
schema: 2.0.0
---

# New-FudgePopTemplate

## SYNOPSIS
Clone an XML template for custom needs

## SYNTAX

```
New-FudgePopTemplate [-OutputFile] <String> [-Overwrite] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Clones the default XML template for use in creating a custom control file.

## EXAMPLES

### EXAMPLE 1
```
Clone-FudgePopTemplate -OutputFile 'c:\templates\custom.xml'
```

### EXAMPLE 2
```
Clone-FudgePopTemplate -OutputFile 'c:\templates\custom.xml' -Overwrite
```

## PARAMETERS

### -OutputFile
Path to save the cloned template file.

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

### -Overwrite
Overwrite existing destination file if it exists

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
