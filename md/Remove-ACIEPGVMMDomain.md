---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Remove-ACIEPGVMMDomain

## SYNOPSIS
Removes VMM Domain Association from EPG

## SYNTAX

```
Remove-ACIEPGVMMDomain [-Tenant] <String> [-AP] <String> [-EPG] <String> [-VMMDomain] <String>
 [<CommonParameters>]
```

## DESCRIPTION
Removes VMM Domain Association from EPG

## EXAMPLES

### Example 1
```
PS C:\> New-ACIEPGVMMDomain -Tenant "MyTenant" -AP "AP" -EPG "Test-EPG" -VMMDomain "ACI_PhysDomain" -Vlan 238 `
```

@{totalCount=0; imdata=System.Object\[\]}

## PARAMETERS

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

### -EPG
Endpoint Group

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

### -VMMDomain
VMM Domain Profile

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
