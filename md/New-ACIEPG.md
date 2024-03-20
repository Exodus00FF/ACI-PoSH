---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACIEPG

## SYNOPSIS
Create a new ACI EPG

## SYNTAX

```
New-ACIEPG [[-Tenant] <String>] [[-AP] <String>] [[-EPG] <String>] [[-BD] <String>] [[-Description] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Create a new ACI EPG

## EXAMPLES

### EXAMPLE 1
```
New-ACIEPG -Tenant dejungle -AP LoHangingFruit -EPG UmBongo -BD 200-vcentre-drs-001
```

## PARAMETERS

### -AP
Existing AP under Tenant

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

### -BD
Existing Bridge Domain to associate with

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

### -Description
New EPG description

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EPG
New EPG name

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
ACI Tenant

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General notes

## RELATED LINKS
