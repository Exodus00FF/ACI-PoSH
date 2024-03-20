---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIFabricPortLinkLevel

## SYNOPSIS
Get Link Level policies for the ACI Fabric. 
These define speed, duplex, autoneg etc

## SYNTAX

```
Get-ACIFabricPortLinkLevel [<CommonParameters>]
```

## DESCRIPTION
Get Link Level policies for the ACI Fabric. 
These define speed, duplex, autoneg etc

## EXAMPLES

### EXAMPLE 1
```
Get-ACIFabricPortLinkLevel
```

name             speed   autoNeg descr dn
----             -----   ------- ----- --
default          inherit on            uni/infra/hintfpol-default         
100G.auto.ll.pol 100G    on            uni/infra/hintfpol-100G.auto.ll.pol
1G.noauto.ll.pol 1G      off           uni/infra/hintfpol-1G.noauto.ll.pol

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Define URL to pool

## RELATED LINKS
