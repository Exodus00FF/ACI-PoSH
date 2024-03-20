---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACIInterface

## SYNOPSIS
Function to add standard devices to individial switches

## SYNTAX

```
New-ACIInterface [-Switch] <String> [-ProfileName] <String> [-LeafAccessPolicy] <String> [-FromPort] <Int32>
 [-ToPort] <Int32> [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
New-ACIInterface -ProfileName Leaf102_InterfacePolicy -FromPort 39 -ToPort 41 -Switch LEAF_A102 -LeafAccessPolicy db.servers.fe.AccessPortSelector
```

This adds port 39 - 41 to Leaf 102's interface selection policy and names it db.servers.fe.AccessPortSelector

## PARAMETERS

### -FromPort
Switch Port Start number (1-48 ?)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -LeafAccessPolicy
The name you want to call the group of interfaces.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileName
The specfic Leaf Interface Policy that has been already assigned to a leaf switch. 
Typically only one per switch is defined. 
This can be found using the Get-ACIFabricSwitchLeaf-IntProfiles

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Switch
The switch object name to define the interfaces for. 
This can be found by using Get-ACIFabricSwitchLeaf

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToPort
Switch Port End number (1-48 ?)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Usually used for non multihomed servers, non LACP/VPC interfaces or managment ilo/cimc/drac connections

## RELATED LINKS
