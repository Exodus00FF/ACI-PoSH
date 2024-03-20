---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACIVRF

## SYNOPSIS
Create a new VRF within a given tenant

## SYNTAX

```
New-ACIVRF [[-Tenant] <String>] [[-VRF] <String>] [[-Description] <String>] [<CommonParameters>]
```

## DESCRIPTION
Create a new VRF within a given tenant

## EXAMPLES

### EXAMPLE 1
```
New-ACIVRF -Tenant dejungle -VRF amazon -Description 'SA'
```

## PARAMETERS

### -Description
New VRF description

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

### -Tenant
Tenant Name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VRF
New VRF name

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
This function currently returns raw data. 
This needs to be cleaned up. 
However if it does not error, it has worked !

## RELATED LINKS
