---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIFabricAEEP

## SYNOPSIS
Get Attatchable Access Entity Profiles for the ACI Fabric

## SYNTAX

```
Get-ACIFabricAEEP [<CommonParameters>]
```

## DESCRIPTION
Get Attatchable Access Entity Profiles for the ACI Fabric. 
These bind vlan, vxlan and other pools to types of interfaces classes.

## EXAMPLES

### EXAMPLE 1
```
Get-ACIFabricAEEP
```

name         descr dn
----         ----- --
default            uni/infra/attentp-default
infra.aeep         uni/infra/attentp-infra.aeep
vcentre.aeep       uni/infra/attentp-vcentre.aeep storage.aeep       uni/infra/attentp-storage.aeep

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General notes

## RELATED LINKS
