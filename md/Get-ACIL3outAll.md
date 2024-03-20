---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIL3outAll

## SYNOPSIS
Get specific L3out for a given tenant

## SYNTAX

```
Get-ACIL3outAll [[-Tenant] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get specific L3out for a given tenant

## EXAMPLES

### EXAMPLE 1
```
Get-ACIL3outAll -Tenant companyA
```

name    enforceRtctrl descr dn
----    ------------- ----- --
GetOutA export              uni/tn-companyA/out-GetOutA GetOutB export              uni/tn-companyA/out-GetOutB

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
