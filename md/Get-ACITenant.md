---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACITenant

## SYNOPSIS
Fetches all defined Tenants from ACI

## SYNTAX

```
Get-ACITenant [<CommonParameters>]
```

## DESCRIPTION
Gets all defined and system level tenants from ACI

## EXAMPLES

### EXAMPLE 1
```
Get-ACITenant
```

name        descr dn
----        ----- --
infra             uni/tn-infra
common            uni/tn-common
mgmt              uni/tn-mgmt
companyA          uni/tn-companyA
companyB    Co B  uni/tn-companyB
companyC          uni/tn-companyC
cloudMgmt         uni/tn-cloudMgmt
secretAudit       uni/tn-secretAudit

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Probably the most simple function

## RELATED LINKS
