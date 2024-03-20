---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACIAppProfile

## SYNOPSIS
Create a new ACI App Profile

## SYNTAX

```
New-ACIAppProfile [[-Tenant] <String>] [[-AP] <String>] [[-Description] <String>] [<CommonParameters>]
```

## DESCRIPTION
Create a new ACI App Profile

## EXAMPLES

### EXAMPLE 1
```
New-ACIAppProfile -Tenant dejungle -AP LoHangingFruit
```

## PARAMETERS

### -AP
New AppProfile name

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

### -Description
New AppProfile description

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
ACI Tenant name

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

## RELATED LINKS
