---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIFabricVLANPool

## SYNOPSIS
Get VLAN numbers attached to a VLAN Pool

## SYNTAX

```
Get-ACIFabricVLANPool [[-VLANPool] <String>] [[-AllocMode] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get VLAN numbers attached to a VLAN Pool

## EXAMPLES

### EXAMPLE 1
```
Get-ACIFabricVLANPool -VLANPool vcentre.vlans -AllocMode static
```

name allocMode from     to       dn
---- --------- ----     --       --
static    vlan-200 vlan-999 uni/infra/vlanns-\[vcentre.vlans\]-static/from-\[vlan-200\]-to-\[vlan-999\]

## PARAMETERS

### -AllocMode
Vlan Pool allocation mode. 
Sorry its not get automatic !

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VLANPool
Vlan Pool name

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
