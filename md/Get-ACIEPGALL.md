---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIEPGALL

## SYNOPSIS
Gets all EPG's that are defined for an Application Profile (AP)

## SYNTAX

```
Get-ACIEPGALL [[-Tenant] <String>] [[-AP] <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets all EPG's that are defined for an Application Profile (AP)

## EXAMPLES

### EXAMPLE 1
```
Get-ACIEPGALL -Tenant companyA -AP web.appprofile
```

name    prio   descr dn
----    ----   ----- --
web.epg level3       uni/tn-companyA/ap-web.appprofile/epg-web.epg

## PARAMETERS

### -AP
Application Profile. 
Can be extracted from the Get-ACIAppProfileAll command

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Tenant
ACI tenant. 
Can be extracted from the Get-ACITenant command

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

## RELATED LINKS
