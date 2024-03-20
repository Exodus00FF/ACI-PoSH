---
external help file: ACI-PoSH-help.xml
Module Name: ACI-PoSH
online version:
schema: 2.0.0
---

# New-ACIApiCall

## SYNOPSIS
A module to make a RESTful API call to the Cisco ACI APIC infrastucture

## SYNTAX

```
New-ACIApiCall [[-method] <String>] [[-encoding] <String>] [[-url] <String>] [[-headers] <Object>]
 [[-postData] <String>] [<CommonParameters>]
```

## DESCRIPTION
A module to make a RESTful API call to the Cisco ACI APIC infrastucture

## EXAMPLES

### EXAMPLE 1
```
To be added
```

## PARAMETERS

### -encoding
The encoding method used to communicate with the APIC

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

### -headers
HTTP headers for the session

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -method
The HTTP method you wish to use, such as GET, POST, DELETE etc. 
Not all are supported by APIC

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

### -postData
A blob of data (usually JSON) typically for a POST

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

### -url
The specific URL to connect to

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
