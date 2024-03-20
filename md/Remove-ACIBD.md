---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Remove-ACIBD

## SYNOPSIS
Remove Bridge Domain from Tenant

## SYNTAX

```
Remove-ACIBD [-Tenant] <String> [-BD] <String> [<CommonParameters>]
```

## DESCRIPTION
Remove Bridge Domain from Tenant

## EXAMPLES

### Example 1
```
PS C:\> Remove-ACIBD -Tenant dejungle -BD myBD
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
