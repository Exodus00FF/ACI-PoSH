---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# Get-ACIVRF

## SYNOPSIS
Get VRF's defined for a given tenant

## SYNTAX

```
Get-ACIVRF [[-Tenant] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get VRF's defined for a given tenant

## EXAMPLES

### EXAMPLE 1
```
Get-ACIVRF -Tenant companyA
```

name         descr bdEnforcedEnable pcEnfDir pcEnfPref dn
----         ----- ---------------- -------- --------- --
companyA-vrf       no               ingress  enforced  uni/tn-companyA/ctx-companyA-vrf
secret             no               ingress  enforced  uni/tn-companyA/ctx-secret

## PARAMETERS

### -Tenant
ACI tenant. 
Can be extracted from the Get-ACITenant command

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

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
pcEnfDir indicates the point Contacts and other policy control is applied. 
Usually on ingress (like ACL or Firewall ACL) pcEnfPref states whether contracts and other policy control are applied within this VRF. 
Usually enforced.

## RELATED LINKS
