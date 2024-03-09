---
external help file: FudgePop-help.xml
Module Name: FudgePop
online version:
schema: 2.0.0
---

# Set-FPControlPackages

## SYNOPSIS
Install Chocolatey Packages

## SYNTAX

```
Set-FPControlPackages [-DataSet] <Object> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Process Configuration Control: Chocolatey Package Installs and Upgrades

## EXAMPLES

### EXAMPLE 1
```
Set-FPControlPackages -DataSet $xmldata
```

## PARAMETERS

### -DataSet
XML data from control file import

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
