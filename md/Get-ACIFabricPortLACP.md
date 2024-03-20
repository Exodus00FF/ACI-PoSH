---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIFabricPortLACP

## SYNOPSIS
Get Fabric port channel polcies for multiple interface bundles.

## SYNTAX

```
Get-ACIFabricPortLACP [<CommonParameters>]
```

## DESCRIPTION
Get Fabric port channel polcies for multiple interface bundles.

## EXAMPLES

### EXAMPLE 1
```
Get-ACIFabricPortLACP
```

name                      mode   ctrl                                             minLinks maxLinks descr dn
----                      ----   ----                                             -------- -------- ----- --
default                   off    fast-sel-hot-stdby,graceful-conv,susp-individual 1        16             uni/infra/lacplagp-default
active_nostandby.lacp.pol active fast-sel-hot-stdby,graceful-conv                 1        16             uni/infra/lacplagp-active_nostandby.lacp.pol
active.lacp.pol           active fast-sel-hot-stdby,graceful-conv,susp-individual 1        16             uni/infra/lacplagp-active.lacp.pol
static.lacp.pol           off    fast-sel-hot-stdby,graceful-conv,susp-individual 1        16             uni/infra/lacplagp-static.lacp.pol

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
