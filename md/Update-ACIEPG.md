---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Update-ACIEPG

## SYNOPSIS
Updates the EPG, configuring a Contract, Security Domain or Bridge Domain

## SYNTAX

### DefaultSet (Default)
```
Update-ACIEPG [-Tenant] <String> [-AP] <String> [-EPG] <String> [[-Domain] <String>] [[-BD] <String>]
 [<CommonParameters>]
```

### Contract
```
Update-ACIEPG [[-Tenant] <String>] [[-AP] <String>] [[-EPG] <String>] [[-Domain] <String>] [[-BD] <String>]
 [-Contract] <String> [-ContractType] <String> [<CommonParameters>]
```

## DESCRIPTION
Updates the EPG, configuring a Contract, Security Domain or Bridge Domain

## EXAMPLES

## PARAMETERS

### -AP
Application Profile

```yaml
Type: String
Parameter Sets: DefaultSet
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Contract
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BD
{{ Fill BD Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Contract
{{ Fill Contract Description }}

```yaml
Type: String
Parameter Sets: Contract
Aliases:

Required: True
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContractType
{{ Fill ContractType Description }}

```yaml
Type: String
Parameter Sets: Contract
Aliases:
Accepted values: c, p

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain
{{ Fill Domain Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EPG
{{ Fill EPG Description }}

```yaml
Type: String
Parameter Sets: DefaultSet
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Contract
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tenant
{{ Fill Tenant Description }}

```yaml
Type: String
Parameter Sets: DefaultSet
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Contract
Aliases:

Required: False
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
