---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACIInterfaceVPC

## SYNOPSIS
Create a new VPC interface definition for a host and associate to the fabric.

We use the hostname, bondname and minidisc to create a unique identifier. 
These get stored in the format of  'hostname-bondname-minidesc'

An example could be 'ydclwp001-bond0-azweb1'

## SYNTAX

```
New-ACIInterfaceVPC [-hostname] <String> [-bondname] <String> [-minidesc] <String> [-AEEP] <String>
 [-LinkLevel] <String> [-LACP] <String> [-CDP] <String> [-LLDP] <String> [-FromPort] <Int32> [-ToPort] <Int32>
 [-Switch] <String> [<CommonParameters>]
```

## DESCRIPTION
Create a new VPC interface definition for a host and associate to the fabric.

We use the hostname, bondname and minidisc to create a unique identifier. 
These get stored in the format of  'hostname-bondname-minidesc'

An example could be 'ydclwp001-bond0-azweb1'

## EXAMPLES

### Example 1
```
PS C:\> New-ACIInterfaceVPC -hostname host099 -bondname bond0 -minidesc DevOpsLab -AEP vcentre.aeep 
     -LinkLevel default -LACP LACP_active_nostandby -CDP default -LLDP default -Switch Leaf101-102_VPC_Profile 
     -FromPort 5 -ToPort 8
```

## PARAMETERS

### -AEEP
The AEEP which you want to associate the VPC with

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

### -bondname
The agregated interface name. 
For instance you could use use 'bond0', 'gec001' or similar

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

### -CDP
The CDP policy to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FromPort
Start Port number. 
Single numeric ie 1   or   48

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -hostname
The device hostname

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

### -LACP
LACP  Policy to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LinkLevel
Link Level Policy to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LLDP
The LLDP policy to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -minidesc
This is a short interface description. 
No spaces or funny chars. 
Use a project/service such as POC, PROD, YDC or similar

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
The Leaf Switch name usually a VPC pair to associate with

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToPort
{{ Fill ToPort Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 10
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
