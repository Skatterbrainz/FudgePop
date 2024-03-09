---
external help file: FudgePop-help.xml
Module Name: FudgePop
online version:
schema: 2.0.0
---

# Get-FPConfiguration

## SYNOPSIS
Import Control Data from Registry

## SYNTAX

```
Get-FPConfiguration [[-RegPath] <String>] [-Name] <String> [[-Default] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Fetch data from Registry or return Default if none found

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -RegPath
Registry Path (default is HKLM:\SOFTWARE\FudgePop)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $FPRegRoot
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Registry Value name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Default
Data to return if no value found in registry

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

### Registry Key, Value Name, Default Value (if not found in registry)
## OUTPUTS

### Information returned from registry (or default value)
## NOTES

## RELATED LINKS
