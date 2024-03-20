---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACILogin

## SYNOPSIS
A module to authenticate to Cisco ACI APIC infrastucture

## SYNTAX

```
New-ACILogin [[-Apic] <String>] [[-Username] <String>] [[-Password] <SecureString>] [[-StoreLocation] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
A module to authenticate to Cisco ACI APIC infrastucture

## EXAMPLES

### EXAMPLE 1
```
New-ACILogin -Apic MyAPIC -Username MyUsername -Password MyPassword
```

## PARAMETERS

### -Apic
The APIC you wish to connect to. 
Can be a hostname, FQDN or even IP address. 
HTTPS is always assumed.

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

### -Password
The password for the username specified.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StoreLocation
(Optional) A location a hashed password is stored. 
This can be useful for automation tasks.

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

### -Username
The username to connect to the APIC with. 
Must be defined in ACI or downstream AAA as a valid user AND have access.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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
General notes

Check if an APIC was specified.

## RELATED LINKS
