---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACIL3out

## SYNOPSIS
Create a new L3out interface for a given Tenant

* THIS FUNCTION IS INCOMPLETE - It need to add SVI info, interface binding, contracts etc.... needs a lot more work*

## SYNTAX

```
New-ACIL3out [[-Tenant] <String>] [[-VRF] <String>] [[-L3out] <String>] [[-Description] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Create a new L3out interface for a given Tenant

## EXAMPLES

### EXAMPLE 1
```
New-ACIL3out -Tenant dejungle -VRF amazon -L3out escapepod1 -Description 'its the only way out'
```

## PARAMETERS

### -Description
New L3out description

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -L3out
New L3out name

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
VRF name within Tenant

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
