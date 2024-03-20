---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACITenant

## SYNOPSIS
Create a new ACI tenant

## SYNTAX

```
New-ACITenant [[-Tenant] <String>] [[-Description] <String>] [<CommonParameters>]
```

## DESCRIPTION
Create a new ACI tenant

## EXAMPLES

### EXAMPLE 1
```
New-ACITenant -Tenant dejungle -Description 'Its a nightmare out there'
```

## PARAMETERS

### -Description
Description of tenant

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
This function currently returns raw data. 
This needs to be cleaned up. 
However if it does not error, it has worked !

## RELATED LINKS
