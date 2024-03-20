---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIFabricSwitchLeaf

## SYNOPSIS
Gets all leaf switches defined in the fabric

## SYNTAX

```
Get-ACIFabricSwitchLeaf [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-ACIFabricSwitchLeaf
```

name               descr dn
----               ----- --
LEAF_A101                uni/infra/nprof-LEAF_A101
LEAF_A102                uni/infra/nprof-LEAF_A102
LEAF_A101_A102_VPC       uni/infra/nprof-LEAF_A101_A102_VPC

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
The name is used as the main referance for policy. 
These are linked to a nodeID.

## RELATED LINKS
