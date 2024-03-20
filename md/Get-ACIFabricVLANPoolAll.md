---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIFabricVLANPoolAll

## SYNOPSIS
Get all VLAN pools defined within the fabric, along with their allocation method

## SYNTAX

```
Get-ACIFabricVLANPoolAll [<CommonParameters>]
```

## DESCRIPTION
Get all VLAN pools defined within the fabric, along with their allocation method

## EXAMPLES

### EXAMPLE 1
```
Get-ACIFabricVLANPoolAll
```

name          allocMode descr dn
----          --------- ----- --
infra.vlans   dynamic         uni/infra/vlanns-\[infra.vlans\]-dynamic  vcentre.vlans static          uni/infra/vlanns-\[vcentre.vlans\]-static storage.vlans static          uni/infra/vlanns-\[storage.vlans\]-static

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
