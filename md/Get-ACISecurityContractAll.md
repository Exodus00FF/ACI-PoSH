---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACISecurityContractAll

## SYNOPSIS
Get the ACI Security Contracts for a given Tenant

## SYNTAX

```
Get-ACISecurityContractAll [[-Tenant] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get the ACI Security Contracts for a given Tenant

## EXAMPLES

### EXAMPLE 1
```
Get-ACISecurityContractAll -Tenant SnV
```

name     nameAlias scope               dn
----     --------- -----               --
web                context             uni/tn-SnV/brc-web
database           application-profile uni/tn-SnV/brc-database

## PARAMETERS

### -Tenant
The ACI Fabric Tenant

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
