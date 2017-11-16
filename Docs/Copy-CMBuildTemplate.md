---
external help file: CMBuild-help.xml
Module Name: CMBuild
online version: 
schema: 2.0.0
---

# Copy-CMBuildTemplate

## SYNOPSIS
Clone the default XML templates for custom needs

## SYNTAX

```
Copy-CMBuildTemplate [[-Source1] <String>] [[-Source2] <String>] [-Type] <String> [[-OutputPath] <String>]
 [-NoScrub]
```

## DESCRIPTION
Clones the default XML templates for cmbuild and cmsiteconfig
for use offline or publishing to a different online location.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Copy-CMBuildTemplate -Type both -OutputPath '.\control'
```

### -------------------------- EXAMPLE 2 --------------------------
```
Copy-CMBuildTemplate -Type cmbuild -NoScrub
```

## PARAMETERS

### -Source1
Path to source cmbuild xml template.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: Https://raw.githubusercontent.com/Skatterbrainz/CM_Build/master/cm_build.xml
Accept pipeline input: False
Accept wildcard characters: False
```

### -Source2
Path to source cmsiteconfig xml template.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: Https://raw.githubusercontent.com/Skatterbrainz/CM_Build/master/cm_siteconfig.xml
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
Template option: cmbuild, cmsiteconfig, both.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputPath
Location to save new templates

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: $PWD.Path
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoScrub
Copy templates without clearing settings

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

## INPUTS

## OUTPUTS

## NOTES
1.0.6 - 11/16/2017 - David Stein

## RELATED LINKS

