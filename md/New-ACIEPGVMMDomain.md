---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACIEPGVMMDomain

## SYNOPSIS
Adds/Updates ACI VMM Domain Association

## SYNTAX

```
New-ACIEPGVMMDomain [-Tenant] <String> [-AP] <String> [-EPG] <String> [-VMMDomain] <String>
 [-StaticVLAN] <String> [[-VLAN] <Int32>] [[-PrimaryVLAN] <Int32>] [[-MicroSegmentation] <String>]
 [[-Untagged] <String>] [[-PortBinding] <String>] [[-NumberOfPorts] <Int32>] [[-AllowPromiscuous] <String>]
 [[-ForgedTransmits] <String>] [[-MACChanges] <String>] [[-ActiveUplinkOrder] <String>]
 [[-StandbyUplinkOrder] <String>] [[-CustomEPGName] <String>] [[-Delimiter] <String>] [[-Deployment] <String>]
 [[-Resolution] <String>] [[-LagPolicyName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Adds/Updates ACI VMM Domain Association

## EXAMPLES

### Example 1
```
PS C:\> New-ACIEPGVMMDomain -Tenant "MyTenant" -AP "AP" -EPG "Test-EPG" -VMMDomain "ACI_PhysDomain" -Vlan 238
```

@{totalCount=0; imdata=System.Object\[\]}

## PARAMETERS

### -ActiveUplinkOrder
Enter the Active Uplinks in the order you wish, sepereated by commas

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowPromiscuous
Allow Promiscous (Default Reject)

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Accept, Reject

Required: False
Position: 12
Default value: "Reject"
Accept pipeline input: False
Accept wildcard characters: False
```

### -AP
Application Profile

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

### -CustomEPGName
Custom EPG Name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Delimiter
"Enter the Delimiter"

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: , |, ~, ~, @, ^, +, =

Required: False
Position: 18
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Deployment
Deployment Immediacy

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Immediate, OnDemand

Required: False
Position: 19
Default value: "OnDemand"
Accept pipeline input: False
Accept wildcard characters: False
```

### -EPG
End Point Group

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

### -ForgedTransmits
ForgedTransmits

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Accept, Reject

Required: False
Position: 13
Default value: "Reject"
Accept pipeline input: False
Accept wildcard characters: False
```

### -LagPolicyName
LAG Policy Name

```yaml
Type: String
Parameter Sets: (All)
Aliases: LagPolicy

Required: False
Position: 21
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MACChanges
MAC Changes

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Accept, Reject

Required: False
Position: 14
Default value: "Reject"
Accept pipeline input: False
Accept wildcard characters: False
```

### -MicroSegmentation
Use Microsegmentation

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: True, False

Required: False
Position: 8
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NumberOfPorts
Number of Ports for Elastic Bindings

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PortBinding
Port Binding Mode

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Dynamic, Ephemeral, Default, Static-Elastic, Static-Fixed

Required: False
Position: 10
Default value: Static-Elastic
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrimaryVLAN
Primary Vlan or Microsegmentation VLAN

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: MicroSegmentVLAN

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Resolution
Resolution Immediacy

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Immediate, OnDemand, PreProvision

Required: False
Position: 20
Default value: PreProvision
Accept pipeline input: False
Accept wildcard characters: False
```

### -StandbyUplinkOrder
Standby Uplinks in the order you wish, sepereated by commas

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StaticVLAN
Whether to use Static or Dynamic VLAN

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: True, False

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tenant
Tenant

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Untagged
Leave port Untagged

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: True, False, Yes, No

Required: False
Position: 9
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VLAN
VLAN to use for EPG

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: EndpointVLAN

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VMMDomain
Vmware Domain

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
