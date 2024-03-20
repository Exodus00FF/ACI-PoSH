---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIFabricPortLLDP

## SYNOPSIS
Gets the fabric LLDP policies

## SYNTAX

```
Get-ACIFabricPortLLDP [<CommonParameters>]
```

## DESCRIPTION
Gets the fabric LLDP policies. 
More standards based that CDP. 
L2 protocol. 
Useful diagnotic aid, however has security issues. 
Beware !

## EXAMPLES

### EXAMPLE 1
```
Get-ACI-Fabric-Port-LLDP
```

name                adminRxSt adminTxSt descr dn
----                --------- --------- ----- --
default             enabled   enabled         uni/infra/lldpIfP-default
enabled.lldp.pol    enabled   enabled         uni/infra/lldpIfP-enabled.lldp.pol
enabled-tx.lldp.pol disabled  enabled         uni/infra/lldpIfP-enabled-tx.lldp.pol
disabled.lldp.pol   disabled  disabled        uni/infra/lldpIfP-disabled.lldp.pol

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General notes

## RELATED LINKS
