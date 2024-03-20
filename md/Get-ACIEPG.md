---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIEPG

## SYNOPSIS
Gets ACI EndPoint Groups assigned to an Application Profile.

## SYNTAX

```
Get-ACIEPG [-Tenant] <String> [-AP] <String> [-EPG] <String> [<CommonParameters>]
```

## DESCRIPTION
Gets ACI EndPoint Groups assigned to an Application Profile

## EXAMPLES

### EXAMPLE 1
```
Get-ACIEPG -Tenant companyA -AP web.appprofile -EPG web.epg
```

## PARAMETERS

### -AP
Application Profile. 
Can be extracted from the Get-ACIAppProfileAll command

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
EndPoint Group. 
Can be extracted from the Get-ACIAppProfile command

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
ACI tenant. 
Can be extracted from the Get-ACITenant command

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

## OUTPUTS

## NOTES
General notes

## RELATED LINKS
