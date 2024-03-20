---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIL3out

## SYNOPSIS
Gets detail about a specific L3out interface

## SYNTAX

```
Get-ACIL3out [[-Tenant] <String>] [[-L3out] <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets detail about a specific L3out interface

## EXAMPLES

### EXAMPLE 1
```
Get-ACIL3out -Tenant companyA -L3out GetOutB
```

## PARAMETERS

### -L3out
L3out interface name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Tenant
ACI tenant. 
Can be extracted from the Get-ACITenant command

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General notes

## RELATED LINKS
