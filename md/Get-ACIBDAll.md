---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIBDAll

## SYNOPSIS
Get all ACI Bridge Domains for a given Tenant

## SYNTAX

```
Get-ACIBDAll [[-Tenant] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get all ACI Bridge Domains for a given Tenant

## EXAMPLES

### EXAMPLE 1
```
Get-ACIBDAll -Tenant companyA
```

name            descr dn
----            ----- --
500-DB-DATA-001       uni/tn-companyA/BD-500-DB-DATA-001 201-WEB-BE-001        uni/tn-companyA/BD-201-WEB-BE-001  200-WEB-FE-001        uni/tn-companyA/BD-200-WEB-FE-001

## PARAMETERS

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

## RELATED LINKS
