---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIEpgBD

## SYNOPSIS
Gets a list of all Bridge Domain Bindings

## SYNTAX

### ALL (Default)
```
Get-ACIEpgBD [<CommonParameters>]
```

### EPG
```
Get-ACIEpgBD [-Tenant] <String> [-AP] <String> [-EPG] <String> [<CommonParameters>]
```

### AP
```
Get-ACIEpgBD [-Tenant] <String> [-AP] <String> [<CommonParameters>]
```

### Tenant
```
Get-ACIEpgBD [-Tenant] <String> [<CommonParameters>]
```

## DESCRIPTION
Gets all Bridge Domains formed with an EPG that are present in ACI. 
Depending on the Input. 
No input means all Tenants will be searched.

## EXAMPLES

### EXAMPLE 1
```
Get-ACIEpgBD  | FL
```

### EXAMPLE 2
```
Get-ACIEpgBD -Tenant "common"  | FL
```

### EXAMPLE 3
```
Get-ACIEpgBD -Tenant "common" -AP "default"  | FL
```

### EXAMPLE 4
```
Get-ACIEpgBD -Tenant "common" -AP "default" -EPG "EPG-FailedAuth" | FL
```

## PARAMETERS

### -AP
Application Profile to be Searched (Mandatory if used with EPG param)

```yaml
Type: String
Parameter Sets: EPG, AP
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EPG
Specific End Point group to be Searched

```yaml
Type: String
Parameter Sets: EPG
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tenant
Tenant to be Searched (Mandatory if used with AP and/or EPG params)

```yaml
Type: String
Parameter Sets: EPG, AP, Tenant
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Returns the \[psobject\[\]\]
EPG, EPG-DN, AP, Tenant, Bridge Domain, Bridge Domain DN.

## RELATED LINKS
