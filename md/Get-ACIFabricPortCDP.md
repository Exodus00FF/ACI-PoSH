---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIFabricPortCDP

## SYNOPSIS
Gets the fabric CDP policies

## SYNTAX

```
Get-ACIFabricPortCDP [<CommonParameters>]
```

## DESCRIPTION
Gets the fabric CDP policies. 
Cisco proprietory protocol. 
L2 protocol. 
Useful diagnotic aid, however has security issues. 
Beware !

## EXAMPLES

### EXAMPLE 1
```
Get-ACIFabricPortCDP
```

name             adminSt  descr dn
----             -------  ----- --
default          disabled       uni/infra/cdpIfP-default
enabled.cdp.pol  enabled        uni/infra/cdpIfP-enabled.cdp.pol  disabled.cdp.pol disabled       uni/infra/cdpIfP-disabled.cdp.pol

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General notes

## RELATED LINKS
