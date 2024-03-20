---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACIBD

## SYNOPSIS
Create a new Bridge Domain for a given Tenant and VRF.

## SYNTAX

```
New-ACIBD [-Tenant] <String> [-VRF] <String> [-BD] <String> [[-SVI] <String>] [[-SVIscope] <String>]
 [[-L3out] <String>] [<CommonParameters>]
```

## DESCRIPTION
Create a new Bridge Domain for a given Tenant and VRF.

## EXAMPLES

### Example 1
```
PS C:\> New-ACIBD -Tenant dejungle -VRF amazon -BD 200-vcentre-drs-001 -L3out escapepod1 -SVI 3.3.3.1/28 -SVIscope public
```

## PARAMETERS

### -BD
Bridge Domain

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

### -L3out
The L3out interface to associate the BD with.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SVI
The SVI interface is CIDR standard. 
Such as 10.0.0.1/8 or 172.16.32.65/28

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SVIscope
This needs to be set to public (if you want the BD to be advertised and accessible externally) or private Function defaults to 'public'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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

### -VRF
VRF

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
