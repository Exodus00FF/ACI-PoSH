
Function Get-ACIFabricVlanPool{

	[cmdletbinding(DefaultParameterSetName='Default')]
    param(
        
        # Parameter help description
        [Parameter(ParameterSetName='Name')]
        [string]
        [alias('name')]
        $PoolName,

        [Parameter(ParameterSetName='DN')]
        [string]
        [alias('dn')]
        $PoolDN
    )


        
    $PollURL = "https://{0}/api/node/mo/uni/infra.json?query-target=children&target-subtree-class=fvnsVlanInstP&query-target=subtree&target-subtree-class=fvnsRtVlanNs,fvnsEncapBlk" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $IMData = ($PollRaw.httpResponse | ConvertFrom-Json).imdata


    $VLanDomains = $IMDATA | Where-Object { $($_ | Get-member -Name fvnsRtVlanNs)} | Select-Object -ExpandProperty fvnsRtVlanNs | Select-Object -ExpandProperty Attributes
    $EncapBlock = $IMDATA | Where-Object { $($_ | Get-member -Name fvnsEncapBlk)} | Select-Object -ExpandProperty fvnsEncapBlk | Select-Object -ExpandProperty Attributes
    $VlanIns = $IMDATA | Where-Object { $($_ | Get-member -Name fvnsVlanInstP)} | Select-Object -ExpandProperty fvnsVlanInstP | Select-Object -ExpandProperty Attributes


    $Pools = $(foreach($VlanPool in $VlanIns){
        

        foreach($VlanDomain in $($VLanDomains | Where-Object { $_.dn -Match [regex]::escape($VlanPool.dn)})){$VlanDomain}
        [PSCustomObject]@{
            allocMode    = $VlanPool.allocMode
            annotation   = $VlanPool.annotation
            childAction  = $VlanPool.childAction
            configIssues = $VlanPool.configIssues
            descr        = $VlanPool.descr
            dn           = $VlanPool.dn
            extMngdBy    = $VlanPool.extMngdBy
            lcOwn        = $VlanPool.lcOwn
            modTs        = $VlanPool.modTs
            monPolDn     = $VlanPool.monPolDn
            name         = $VlanPool.name
            nameAlias    = $VlanPool.nameAlias
            ownerKey     = $VlanPool.ownerKey
            ownerTag     = $VlanPool.ownerTag
            status       = $VlanPool.status
            uid          = $VlanPool.uid
            userdom      = $VlanPool.userdom
            Domains      = @([pscustomobject]$($VLanDomains | Where-Object { $_.dn -Match [regex]::escape($VlanPool.dn)} | Select-Object 'dn','lcOwn','modTs','status','tCl','tDn'))

            VlanIDs      = @(
                foreach($Encap in $($EncapBlock | Where-Object { $_.dn -Match [regex]::escape($VlanPool.dn)})){
                    @(($Encap.From -replace "[^\d]",'' )..($Encap.To -replace "[^\d]",'' ))
                }
            )

            VLANID_SH = @(
                $Numbers=foreach($Encap in $($EncapBlock | Where-Object { $_.dn -Match [regex]::escape($VlanPool.dn)})){
                    @(($Encap.From -replace "[^\d]",'' )..($Encap.To -replace "[^\d]",'' ))
                }
                $i=0
                $Result = [string[]]@()
                while($i -lt $Numbers.count){
                    $Start = $Numbers[$i]

                    while (($i+1 -lt $Numbers.count) -and (($Numbers[$i + 1]) -eq ($Numbers[$i] +1))){
                        $i++

                    }
                    $end= $Numbers[$i]

                    if($start -eq $end){
                        $Result += "$Start"
                    } else { 
                        $Result += "$start-$end"
                    } 
                    $i++
                }
                $Result -join ","
            )

            Vlans        = @(
                foreach($Encap in $($EncapBlock | Where-Object { $_.dn -Match [regex]::escape($VlanPool.dn)})){

                    $Global:x = $_
                    [PSCustomObject]@{
                        allocMode   = $Encap.allocMode
                        allocModeEffective = switch($Encap.allocMode){
                            "inherit" {$Vlan.allocMode; break }
                            "static"  {$Encap.allocMode; break }
                            "dynamic" {$Encap.allocMode; break }
                        }
                        annotation  = $Encap.annotation
                        childAction = $Encap.childAction
                        descr       = $Encap.descr
                        dn          = $Encap.dn
                        extMngdBy   = $Encap.extMngdBy
                        from        = $Encap.from
                        lcOwn       = $Encap.lcOwn
                        modTs       = $Encap.modTs
                        monPolDn    = $Encap.monPolDn
                        name        = $Encap.name
                        nameAlias   = $Encap.nameAlias
                        role        = $Encap.role
                        status      = $Encap.status
                        to          = $Encap.to
                        uid         = $Encap.uid
                        userdom     = $Encap.userdom
                        RawVlanID   = @(($Encap.From -replace "[^\d]",'' )..($Encap.To -replace "[^\d]",'' ))
                    }
                }

            )
        }

    })

    
    if("$PoolName" -ne ''){
        return $($Pools | Where-Object Name -eq $PoolName)
    }elseif("$Pooldn" -ne ''){
        return $($Pools | Where-Object dn -eq $PoolDN)
    }else{
        return $Pools
    }
}

Function Add-ACIFabricVlanPoolVlan{
    
	[cmdletbinding()]
    param(
        

        [Parameter(Mandatory, ParameterSetName="PoolName-VLANID")]
        [Parameter(Mandatory, ParameterSetName="PoolName-VLANRange")]
        [string]
        [alias('name')]
        $VlanPoolName,

        [ValidatePattern("^uni/infra/vlanns-\[[^\]]+]\-(?:static|dynamic)$")]
        [Parameter(Mandatory, ParameterSetName="PoolDN-VLANID")]
        [Parameter(Mandatory, ParameterSetName="PoolDN-VLANRange")]
        [string]
        [alias('dn')]
        $VlanPoolDN,

        [Parameter(Mandatory, ParameterSetName="PoolName-VLANID")]
        [Parameter(Mandatory, ParameterSetName="PoolDN-VLANID")]
        [int32]
        [ValidateRange(1,4096)]
        $VlanID,

        [Parameter(Mandatory, ParameterSetName="PoolName-VLANRange")]
        [Parameter(Mandatory, ParameterSetName="PoolDN-VLANRange")]
        [int32]
        [ValidateRange(1,4096)]
        $FromVlan,

        [Parameter(Mandatory, ParameterSetName="PoolName-VLANRange")]
        [Parameter(Mandatory, ParameterSetName="PoolDN-VLANRange")]
        [int32]
        [ValidateRange(1,4096)]
        $ToVlan,

        
        [Parameter(Mandatory, ParameterSetName="PoolName-VLANID")]
        [Parameter(Mandatory, ParameterSetName="PoolName-VLANRange")]
        [Parameter(Mandatory, ParameterSetName="PoolDN-VLANID")]
        [Parameter(Mandatory, ParameterSetName="PoolDN-VLANRange")]
        [string]
        $Description,

        
        [Parameter(Mandatory, ParameterSetName="PoolName-VLANID")]
        [Parameter(Mandatory, ParameterSetName="PoolName-VLANRange")]
        [Parameter(Mandatory, ParameterSetName="PoolDN-VLANID")]
        [Parameter(Mandatory, ParameterSetName="PoolDN-VLANRange")]
        [string]
        [ValidateSet('static','inherit','dynamic')]
        $AllocationMode,

            
        [Parameter( ParameterSetName="PoolName-VLANID")]
        [Parameter( ParameterSetName="PoolName-VLANRange")]
        [Parameter( ParameterSetName="PoolDN-VLANID")]
        [Parameter( ParameterSetName="PoolDN-VLANRange")]
        [string]
        [ValidateSet('Internal','ExternalOnWire', IgnoreCase)]
        $Role="ExternalOnWire"
    )

    
    if($PSCmdlet.ParameterSetName -match '^PoolName-' ){
        Write-Verbose "[Add-ACIFabricVlanPoolVlan] Vlan Pool Name: $VlanPoolName"
        $Pool = Get-ACIFabricVlanPool -Name $VlanPoolName

    }else{
        Write-Verbose "[Add-ACIFabricVlanPoolVlan] Vlan Pool DN: $VlanPoolDN"
        $Pool = Get-ACIFabricVlanPool -dn $VlanPoolDN
    }


    $VlanPoolDN = $Pool.dn
    Write-Verbose "[Add-ACIFabricVlanPoolVlan] Used Poolname: $VlanPoolDN"

    #Build the From & To Fields
    if($PSCmdlet.ParameterSetName -match '-VLANID$' ){
       [int32] $FromVlan = $VlanID
       [int32] $ToVlan = $VlanID
    }

    Write-Verbose "[Add-ACIFabricVlanPoolVlan] FromVlan: $FromVlan"
    Write-Verbose "[Add-ACIFabricVlanPoolVlan] ToVlan: $ToVlan"

    #Check the VLAN Pool to see if one of the vlans already exists, then exit if there is a match
    $ExistingVlans = @(foreach($VlanID in $Pool.VlanIDs){
        if($VlanID -iin ($FromVlan..$ToVlan)){
            $VlanID
        }
    })
    if($ExistingVlans.count -gt 0){
        Write-Warning "The Following Vlans already exist in Vlan Policy:  $($ExistingVlans -join ', ')"
        Write-Error "Vlan Already Exists:  $($ExistingVlans -join ', ')"
        return $Null
    }

    $Body = [Ordered]@{ 
        fvnsEncapBlk = [Ordered]@{
            attributes = [Ordered]@{
                dn = '{0}/from-[vlan-{1}]-to-[vlan-{2}]' -f $VlanPoolDN,$FromVlan,$ToVlan
                from      = "vlan-{0}" -f $FromVlan
                to        = "vlan-{0}" -f $ToVlan
                allocMode = $AllocationMode.toLower()
                descr     = $Description
                rn        = "from-[vlan-{0}]-to-[vlan-{1}]" -f $FromVlan,$ToVlan
                status    = "created"
            }
        }
    }


    if ($Role -ne 'ExternalOnWire'){
        $Body.fvnsEncapBlk.attributes.Add('role','internal')
    }

    Write-verbose "[Add-ACIFabricVlanPoolVlan] :`r`n$($Body | convertto-json)"

    $PollURL = "https://{0}/api/node/mo/{1}.json" -f $global:ACIPoSHAPIC,$Body.fvnsEncapBlk.attributes.dn

    Write-Verbose "[Add-ACIFabricVlanPoolVlan] Poll URL: $PollURL"
    $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $($Body | convertto-json -Compress -Depth 100)
    return $PollRaw
}


Function Remove-ACIFabricVlanPoolVlan {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        [validatePattern('^uni/infra/vlanns-\[[^\]]+]-(dynamic|static)/from-\[vlan-\d+]-to-\[vlan-\d+]$')]
        $dn


   )

   $Body = [Ordered]@{
    fvnsEncapBlk = [Ordered]@{
     attributes = [Ordered]@{
        dn=$DN
        status = 'deleted'
     }
    }
   }

   
    Write-verbose "[Remove-ACIFabricVlanPoolVlan] :`r`n$($Body | convertto-json)"

    $PollURL = "https://{0}/api/node/mo/{1}.json" -f $global:ACIPoSHAPIC,$DN

    Write-Verbose "[Remove-ACIFabricVlanPoolVlan] Poll URL: $PollURL"
    $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $($Body | convertto-json -Compress -Depth 100)
    return $PollRaw

}



function Get-ACIFabricLeafSwitches{
    [alias('Get-ACIFabricLeafs')]
    [CmdletBinding()]
    param(
    )
    
    $PollURL = 'https://{0}/api/node/class/fabricNode.json?query-target-filter=and(eq(fabricNode.role,"leaf"),eq(fabricNode.fabricSt,"active"),ne(fabricNode.nodeType,"virtual"))' -f $Global:ACIPoSHAPIC

    $PollRaw = Start-ACICommand -Method GET -Url $PollURL 

    return [pscustomobject] $PollRaw.httpResponse | 
                            ConvertFrom-Json | 
                            Select-Object -ExpandProperty imdata | 
                            Select-Object -ExpandProperty fabricNode  | 
                            select-object -ExpandProperty attributes | 
                            Select-Object *, 
                                @{Label='PodID';Expression={[regex]::match($_.dn,"pod-(?<podid>[\d+]+)").Groups['podid'].value}}

}

function Get-ACIFabricSpineSwitches{
    [alias('Get-ACIFabricSpines')]
    [CmdletBinding()]
    param(
    )
    
    $PollURL = 'https://{0}/api/node/class/fabricNode.json?query-target-filter=and(eq(fabricNode.role,"spine"),eq(fabricNode.fabricSt,"active"),ne(fabricNode.nodeType,"virtual"))' -f $Global:ACIPoSHAPIC

    $PollRaw = Start-ACICommand -Method GET -Url $PollURL 

    return [pscustomobject] $PollRaw.httpResponse | 
                            ConvertFrom-Json | 
                            Select-Object -ExpandProperty imdata | 
                            Select-Object -ExpandProperty fabricNode  | 
                            select-object -ExpandProperty attributes | 
                            Select-Object *, 
                                @{Label='PodID';Expression={[regex]::match($_.dn,"pod-(?<podid>[\d+]+)").Groups['podid'].value}}

}


function Get-ACIFabricPortsStandard{
    [alias('Get-ACIFabricPorts','Get-ACIFabricPortsIndividual')]

    [CmdletBinding(DefaultParameterSetName = 'Default')]

    param(
        [string[]]
        [Parameter(Mandatory, ParameterSetName="Node")]
        [parameter()]
        $NodeID,
        
        [int32[]]
        [parameter()]
        $PodID=1
    )


    $LeafSwitches = Get-ACIFabricLeafSwitches
    if($NodeID.count -ne 0){
        $Nodes = $LeafSwitches | Select-Object id,PodID | Where-Object id -iin $NodeID
        Write-Verbose "Matching Nodes: $($Nodes.id -join ", ")"
    }


    if($Null -eq $Nodes -or $Nodes.Count -eq 0 ){
        
        $FabricNodes = $LeafSwitches | Select-Object id,PodID
        Write-Verbose "Matching Nodes: $($Nodes.id -join ", ")"
    }
    


    $ReturnData = foreach ($FabricNode in $FabricNodes){

    $PollURL = 'https://{0}/api/node/class/fabricPathEp.json?query-target-filter=and(eq(fabricPathEp.lagT,"not-aggregated"),or(eq(fabricPathEp.breakT,"nonbroken"),eq(fabricPathEp.breakT,"broken-child")),or(eq(fabricPathEp.pathT,"leaf"),eq(fabricPathEp.pathT,"extchhp")),wcard(fabricPathEp.dn,"topology/pod-{1}/paths-{2}/"),not(or(wcard(fabricPathEp.name,"^tunnel"),wcard(fabricPathEp.name,"^vfc"))))' -f $Global:ACIPoSHAPIC, $FabricNode.PodID, $FabricNode.id

    $PollRaw = Start-ACICommand -Method GET -Url $PollURL 

    [pscustomobject] $PollRaw.httpResponse | 
                            ConvertFrom-Json | 
                            Select-Object -ExpandProperty imdata | 
                            Select-Object -ExpandProperty fabricpathep  | 
                            select-object -ExpandProperty attributes | 
                            Select-Object *, 
                                @{Label='PodID';Expression={[regex]::match($_.dn,"pod-(?<podid>[\d+]+)").Groups['podid'].value}},
                                @{Label='SwitchID';Expression={[regex]::match($_.dn,"paths-(?<swid>[^/]+)").Groups['swid'].value}},
                                @{Label='PortNumber';Expression={[int32][regex]::match($_.dn,"eth\d+[\\//](?<port>[\d+]+)").Groups['port'].value}}

    }

    return $ReturnData
}

function Get-ACIPodIDs {
    [cmdletbinding()]
    param()

    $PollURL = 'https://{0}/api/node/mo/info.json' -f $Global:ACIPoSHAPIC

    $PollRaw = Start-ACICommand -Method GET -Url $PollURL 


    return [pscustomobject] $PollRaw.httpResponse | 
                            ConvertFrom-Json | 
                            Select-Object -ExpandProperty imdata | 
                            Select-Object -ExpandProperty topinfo  | 
                            select-object -ExpandProperty attributes

}

function Get-ACIFabricPortChannelPaths{
    [alias('Get-ACIFabricPCPaths')]
    [CmdletBinding()]
    param(
    )

    $PollURL = 'https://{0}/api/node/class/fabricPathEp.json?query-target-filter=eq(fabricPathEp.lagT,"link")' -f $Global:ACIPoSHAPIC

    $PollRaw = Start-ACICommand -Method GET -Url $PollURL 

    return [pscustomobject] $PollRaw.httpResponse | 
                            ConvertFrom-Json | 
                            Select-Object -ExpandProperty imdata | 
                            Select-Object -ExpandProperty fabricpathep  | 
                            select-object -ExpandProperty attributes | 
                            Select-Object *, 
                                @{Label='PodID';Expression={[regex]::match($_.dn,"pod-(?<podid>[\d+]+)").Groups['podid'].value}},
                                @{Label='SwitchID';Expression={[regex]::match($_.dn,"paths-(?<swid>[^/]+)").Groups['swid'].value}}

}

#
function Get-ACIFabricVirtualPortChannelPaths{
    [alias('Get-ACIFabricVPCPaths','Get-ACIFabricVirtualPCPaths')]
    [CmdletBinding()]
    param(
    )

    $PollURL = 'https://{0}/api/node/class/fabricPathEp.json?query-target-filter=and(eq(fabricPathEp.lagT,"node"),wcard(fabricPathEp.dn,"^topology/pod-[\d]*/protpaths-"))' -f $Global:ACIPoSHAPIC

    $PollRaw = Start-ACICommand -Method GET -Url $PollURL 


    return [pscustomobject] $PollRaw.httpResponse | 
                            ConvertFrom-Json | 
                            Select-Object -ExpandProperty imdata | 
                            Select-Object -ExpandProperty fabricpathep  | 
                            select-object -ExpandProperty attributes | 
                            Select-Object *, 
                                @{Label='PodID';Expression={[regex]::match($_.dn,"pod-(?<podid>[\d+]+)").Groups['podid'].value}},
                                @{Label='SwitchID';Expression={[regex]::match($_.dn,"paths-(?<swid>[^/]+)").Groups['swid'].value}}

}


function Get-ACIDHCPPolicy {
    [cmdletbinding()]
    param(        [string]
        [parameter(Mandatory)]
        $Tenant
    )
        
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=children&target-subtree-class=dhcpRelayP" -f $global:ACIPoSHAPIC, $Tenant
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $Return = $PollRaw.httpResponse | ConvertFrom-Json | Select-Object -ExpandProperty imdata  | Select-Object -ExpandProperty dhcpRelayP | Select-Object -ExpandProperty attributes

    return $Return
}


function Get-ACIDHCPOptions {
    [cmdletbinding()]
    param(        
        [string]
        [parameter(Mandatory)]
        $Tenant
    )

    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=children&target-subtree-class=dhcpOptionPol" -f $global:ACIPoSHAPIC, $Tenant
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $Return = $PollRaw.httpResponse | ConvertFrom-Json | Select-Object -ExpandProperty imdata  | Select-Object -ExpandProperty dhcpOptionPol | Select-Object -ExpandProperty attributes
    return $Return
}


Function get-ACIBDDHCPPolicy {
    [cmdletbinding()]
    param (

        [string]    
        [parameter(Mandatory)]
        $Tenant,
        
        [string]    
        [parameter(Mandatory)]
        $BD
    )
    
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}.json?query-target=children&target-subtree-class=dhcpLbl" -f $GLobal:ACIPoSHAPIC, $Tenant, $BD

    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return [pscustomobject] $($PollRaw.httpResponse | ConvertFrom-Json | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty dhcpLbl | Select-Object -ExpandProperty attributes)

}

Function Add-ACIBDDHCPRelayPolicy{
    [cmdletbinding()]
    [alias('Add-BDDHCPRelayPolicy')]
    param (

        [string]    
        [parameter(Mandatory)]
        $Tenant,
        
        [string]    
        [parameter(Mandatory)]
        $BD,

        [string]    
        [parameter(Mandatory)]
        $DHCPLabelName,

        [string]
        [parameter(Mandatory)]
        [ValidateSet('tenant','infra')]
        $Scope,

        [parameter()]
        $DHCPOptionsName=""
    )

    $DN = "uni/tn-{0}/BD-{1}/dhcplbl-{2}" -f $Tenant, $BD, $DHCPLabelName

    $PollURL = "https://{0}/api/node/mo/{1}.json" -f $GLobal:ACIPoSHAPIC, $DN

    $PollBody = [Ordered]@{
        dhcpLbl = [Ordered]@{
            attributes= [Ordered]@{
                dn = $DN
                owner = "tenant"
                name ="$DHCPLabelName"
                rn ="dhcplbl-$DHCPLabelName"
                status = "created"
            }
            children= @(
                [Ordered]@{
                dhcpRsDhcpOptionPol = [Ordered]@{
                    attributes= [ordered] @{
                        tnDhcpOptionPolName=$DHCPOptionsName
                        status = "created,modified"
                    } 
                    children=@()
                }
            })
        }
    }

    if($Scope -eq 'infra'){
        $PollBody.dhcplbl.attributes.remove('owner')
    }

    if ("$($DHCPOptionsName.Trim())" -eq ''){
        $PollBody.dhcpLbl.remove('children')
    }

    

    $JSON = $PollBody | ConvertTo-Json -Depth 10 -Compress
    Write-Verbose "[Add-BDDHCPRelayPolicy] JSON: $($PollBody | ConvertTo-Json -Depth 10)"
    $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $JSON

    if($PollRaw.httpCode -ge 200 -and $pollRaw.httpCode -lt 300){
        return [pscustomobject]@{
            httpcode = $PollRaw.httpCode
            dn       =  $DN
            success  = $True
        }
    }else{
        return [pscustomobject]@{
            httpcode = $PollRaw.httpCode
            dn       =  ""
            success  = $False
        }
    }

}


function Remove-ACIObjectByDN {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory,ParameterSetName="DN")]
        [validatePattern('uni/.*')]
        $DN,

        [parameter(Mandatory)]
        [Alias('JSONVariableName','VarName')]
        $VariableName
    )

    $PollURL	= "https://{0}/api/node/mo/{1}.json" -f $global:ACIPoSHAPIC, $DN

    $PollBody = [ordered]@{
        $VariableName = [ordered]@{
            attributes = @{
                dn = $DN
                status             = "deleted"
            }
            children = [system.collections.arraylist]@()
        }
    }

    $PollBodyJson = $PollBody | ConvertTo-Json -Depth 10 -Compress

    Write-Verbose "[Remove-ACIObjectByDN] JSON: $PollBodyJSON"
    Write-Verbose "[Remove-ACIObjectByDN] Poll URL: $PollURL"
    if($PSCmdlet.ShouldProcess("Start-ACICommand")){
        
        $PollRaw = Start-ACICommand -URL $PollURL -Method POST -PostData $PollBodyJson
        
        if (!($PollRaw.httpCode -eq 200)) {
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Write-Error -Category MetadataError -Message  'An error occured after calling the API.  Function failed.'
            
        }else{
            return $True
        }

    }else{
        Write-Host "Would Execute Start-ACICommand -URL $PollURL -Method POST -PostData ""$PollBodyJson"""
    }
    


}


function remove-ACIEPGStaticPort {
    [CmdletBinding(DefaultParameterSetName = 'DN')]
    param(
        [parameter(Mandatory,ParameterSetName="DN")]
        [validatePattern('uni/tn-[^/]+/ap-[^/]+/epg-[^/]+/rspathAtt-\[topology/pod-\d+/(?:protpaths|paths)-[\d\-]+/pathep-\[[^\]]+]]')]
        $DN
    )

    $PollURL	= "https://{0}/api/node/mo/{1}.json" -f $global:ACIPoSHAPIC, $DN
        
    $PollBody = [ordered]@{
        fvRsPathAtt = [ordered]@{
            attributes = @{
                dn = $DN
                status             = "deleted"
            }
            children = [system.collections.arraylist]@()
        }
    }
    $PollRaw = Start-ACICommand -URL $PollURL -Method POST -PostData $($PollBody | ConvertTo-Json -Depth 10 -Compress)
    

    if (!($PollRaw.httpCode -eq 200)) {
        # Needs better output here but for now output
        $PollRaw.httpCode
        $PollRaw
        Write-Error -Category MetadataError -Message  'An error occured after calling the API.  Function failed.'
        
    }else{
        return $True
    }

}
function Add-ACIEPGStaticPort {
        [CmdletBinding(DefaultParameterSetName = 'Default')]
        [Alias("Add-ACIEPGStaticPath")]
   
    param(
        [string]
        [parameter(ValueFromPipelineByPropertyName,Mandatory)]
        $Tenant,
        
        [string]
        [parameter(ValueFromPipelineByPropertyName,Mandatory)]
        $AP,

        [string]
        [parameter(ValueFromPipelineByPropertyName,Mandatory)]
        $EPG,

        [String]  
        [parameter(Mandatory)]
        [ValidateSet("port","PC","VPC", IgnoreCase=$true)]
        $PathGroup,

        [string]
        [Parameter(Mandatory = $True, ParameterSetName="DN")]
        [alias('InterfaceDN')]
        [ValidatePattern('topology/pod-\d+/(?:protpaths|paths)-[\d\-]+/pathep-\[[^\]]+]')]
        $PathDN,
        
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Interface")]
        [alias("SwitchID")]
        $SwitchNodeID,
                
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Interface")]
        [alias('VPCPath','ProtPath')]
        $PATH,
        
        [string]
        [parameter(Mandatory)]
        [ValidateSet("immediate","OnDemand", IgnoreCase=$true)]
        $Immediacy,

        [int32]
        [parameter(Mandatory)]
        [alias('SecondaryVLAN')]
        $VLAN,
        
        [int32]
        [parameter()]
        [alias('PrimaryVlan',"PortEncapVlan")]
        $MicrosegmentedVLAN,
                
        [string]
        [parameter(Mandatory)]
        [ValidateSet("Trunk","8021P","Access", IgnoreCase=$true)]
        $PortMode,

        [int32]
        [Parameter(Mandatory = $False, ParameterSetName="Interface")]
        [parameter()]
        $PodID=1

    )

  
    switch($PortMode){
        "8021P"{$PortModeValue = 'native' }
        "Access"{$PortModeValue = 'untagged' }
        default {$PortModeValue = ''}
    }

    switch($PathGroup){
        "port"{
            if($PATH -notmatch "eth\d+/\d+" -and "$PathDN" -eq ""){
                Write-Error "PATH must be in the form of ""ethN/N"",  i.e.  ""eth1/24""" -ErrorAction Stop
            } 

            if("$PathDN" -eq "" ){
                $PathDN = "topology/pod-{0}/paths-{1}/pathep-[{2}]" -f $PodID,$SwitchNodeID,$PATH
            }
            $PollURL  = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/rspathAtt-[{4}].json" -f $global:ACIPoSHAPIC, $Tenant, $AP,$EPG,$PathDN
            

            $PollBody = [Ordered]@{
                fvRsPathAtt = [Ordered]@{
                    attributes = [Ordered]@{
                        dn = "uni/tn-{0}/ap-{1}/epg-{2}/rspathAtt-[{3}]" -f $Tenant,$AP,$EPG,$PathDN
                        encap = "vlan-$VLAN"
                        mode = $PortModeValue
                        instrImedcy = 'immediate'
                        primaryEncap = "vlan-$PrimaryEncap"
                        tDn =  $PathDN
                        rn = "rspathAtt-[$PathDN]"
                        status = "created"
                    }
                }
            }
        }
        "PC"{
            if("$PathDN" -eq "" ){
                $PathDN = "topology/pod-{0}/paths-{1}/pathep-[{2}]" -f $PodID,$SwitchNodeID,$PATH
            }
            Write-Verbose "PathDN: $PathDN"
            $PollURL  = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/rspathAtt-[{4}].json" -f $global:ACIPoSHAPIC, $Tenant, $AP,$EPG,$PathDN
            

            #$PollURL  = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/rspathAtt-[topology/pod-{4}/paths-{5}/pathep-[{6}]].json" -f $global:ACIPoSHAPIC, $Tenant, $AP,$EPG,$PodID,$SwitchNodeID,$PATH
            
            $PollBody = [Ordered]@{
                fvRsPathAtt = [Ordered]@{
                    attributes = [Ordered]@{
                        dn = "uni/tn-{0}/ap-{1}/epg-{2}/rspathAtt-[{3}]" -f $Tenant,$AP,$EPG,$PathDN
                        encap = "vlan-$VLAN"
                        mode = $PortModeValue
                        instrImedcy = 'immediate'
                        primaryEncap = "vlan-$PrimaryEncap"
                        tDn =  $PathDN
                        rn = "rspathAtt-[$PathDN]"
                        status = "created"
                    }
                }
            }


      }
        "VPC"{
            if($SwitchNodeID -notmatch "\d+[-]\d+" -and "$PathDN" -eq ""){
                Write-Error -ErrorAction Stop -Message "SwitchNodeID when used with VPC, must be in the form of '<VPCNodeID>-<VPCNodeID>', i.e. '101-102'"
            }
                        if("$PathDN" -eq "" ){
                $PathDN = "topology/pod-{0}/protpaths-{1}/pathep-[{2}]" -f $PodID,$SwitchNodeID,$PATH
            }
            $PollURL  = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/rspathAtt-[{4}].json" -f $global:ACIPoSHAPIC, $Tenant, $AP,$EPG,$PathDN
            
            $PollBody = [Ordered]@{
                fvRsPathAtt = [Ordered]@{
                    attributes = [Ordered]@{
                        dn = "uni/tn-{0}/ap-{1}/epg-{2}/rspathAtt-[{3}]" -f $Tenant,$AP,$EPG,$PathDN
                        encap = "vlan-$VLAN"
                        instrImedcy = 'immediate'
                        mode = $PortModeValue
                        primaryEncap = "vlan-$PrimaryEncap"
                        tDn = $PathDN
                        rn = "rspathAtt-[$PathDN]"
                        status = "created"
                    }
                }
            }
        }
    }



    

    if($PortMode -eq "Trunk"){
        $PollBody.fvRsPathAtt.attributes.Remove('mode')
    }

    if($Immediacy -ne 'immediate' ){
        $PollBody.fvRsPathAtt.attributes.remove('instrImedcy')
    }

    if( $PollBody.fvRsPathAtt.attributes.primaryEncap -eq 'vlan-'){
        $PollBody.fvRsPathAtt.attributes.Remove('primaryEncap')
    }

    $JSON = $PollBody | ConvertTo-Json -Depth 10 -Compress
    Write-Verbose "[$($MyInvocation.MyCommand)]: DN: $($PollBody.fvRsPathAtt.Attributes.dn)"
    Write-Verbose "$($PollBody | ConvertTo-Json -Depth 10)"
    $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $JSON

    if($PollRaw.httpCode -ge 200 -and $pollRaw.httpCode -lt 300){
        return [pscustomobject]@{
            httpcode = $PollRaw.httpCode
            dn       = $PollBody.fvRsPathAtt.Attributes.dn
            success  = $True
        }
    }else{
        return [pscustomobject]@{
            httpcode = $PollRaw.httpCode
            dn       =  ""
            success  = $False
        }
    }

    return $PollRaw

}


function Get-ACIFabricDomains{
        [alias('Get-ACIFabricDomain')]
	[cmdletbinding()]
    param(
        
        # Parameter help description
        [Parameter()]
        [string]
        $Name
        
    )

    $Return=@()
    $Return += Get-ACIFabricFCDomain
    $Return += Get-ACIFabricL2Domain
    $Return += Get-ACIFabricL3Domain
    $Return += Get-ACIFabricPhysicalDomain
    $Return += Get-ACIFabricVMMDomain

    if("$Name" -eq ''){
        return $Return

    }else{
        return ($Return | Where-Object Name -eq $Name)

    }
    

}


function Get-ACIFabricPhysicalDomain{
    [alias('Get-ACIFabricPhysicalDomains')]
	[cmdletbinding()]
    param(
        
        # Parameter help description
        [Parameter()]
        [string]
        $Name
    )
    
    $PollURL = "https://{0}/api/node/class/physDomP.json" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $Domains = $PollRaw.httpResponse | ConvertFrom-Json | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty physDomP | Select-Object -ExpandProperty attributes

    if("$Name" -eq ''){
        return $Domains
    }else{
        return $($Domains | Where-Object Name -eq $Name)
    }

}


function Get-ACIFabricL3Domain{
    [alias('Get-ACIFabricL3Domains')]
	[cmdletbinding()]
    param(
        
        # Parameter help description
        [Parameter()]
        [string]
        $Name
    )
    
    $PollURL = "https://{0}/api/node/class/l3extDomP.json" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $Domains = $PollRaw.httpResponse | ConvertFrom-Json | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty l3extDomP | Select-Object -ExpandProperty attributes

    if("$Name" -eq ''){
        return $Domains
    }else{
        return $($Domains | Where-Object Name -eq $Name)
    }

}


function Get-ACIFabricFCDomain{
    [alias('Get-ACIFabricFCDomains','Get-ACIFabricFibreChannelDomains','Get-ACIFabricFibreChannelDomain')]
	[cmdletbinding()]
    param(
        
        # Parameter help description
        [Parameter()]
        [string]
        $Name
    )
    
    $PollURL = "https://{0}/api/node/class/fcDomP.json" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $Domains = $PollRaw.httpResponse | ConvertFrom-Json | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty fcDomP | Select-Object -ExpandProperty attributes

    if("$Name" -eq ''){
        return $Domains
    }else{
        return $($Domains | Where-Object Name -eq $Name)
    }

}



function Get-ACIFabricL2Domain{
    [alias('Get-ACIFabricL2Domains','Get-ACIFabricLayer2Domains','Get-ACIFabricLayer2Domain')]
	[cmdletbinding()]
    param(
        
        # Parameter help description
        [Parameter()]
        [string]
        $Name
    )
    
    $PollURL = "https://{0}/api/node/class/l2extDomP.json" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $Domains = $PollRaw.httpResponse | ConvertFrom-Json | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty l2extDomP | Select-Object -ExpandProperty attributes

    if("$Name" -eq ''){
        return $Domains
    }else{
        return $($Domains | Where-Object Name -eq $Name)
    }

}


function Get-ACIFabricVMMDomain{
    [alias('Get-ACIFabricVMMDomains')]
	[cmdletbinding()]
    param(
        
        # Parameter help description
        [Parameter()]
        [string]
        $Name
    )
    
    $PollURL = "https://{0}/api/node/class/vmmDomP.json" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $Domains = $PollRaw.httpResponse | ConvertFrom-Json | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty vmmDomP | Select-Object -ExpandProperty attributes

    if("$Name" -eq ''){
        return $Domains
    }else{
        return $($Domains | Where-Object Name -eq $Name)
    }

}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACITenant {
	[cmdletbinding()]
    param()

    $PollURL = "https://{0}/api/node/class/fvTenant.json" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $TenRawJson = $PollRaw.httpResponse | ConvertFrom-Json

    return $TenRawJson.imData.fvTenant.Attributes | Select-Object name,descr,dn,@{label="Tenant";Expression={$_.name}}
}


# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIAppProfileAll  {
	[cmdletbinding()]
	param
	(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Tenant
    )
    process {
        if (!($Tenant)) {
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
            
        }
        
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=children&target-subtree-class=fvAp" -f $global:ACIPoSHAPIC,$Tenant
    
        $PollRaw = Start-ACICommand -Method GET -Url $PollURL
        return $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvAp.attributes | Select-Object @{Label='ap-name';Expression={$_.name}}, 
                                                                                                  @{Label='ap-alias';Expression={$_.nameAlias}}, 
                                                                                                  @{Label='ap-descr';Expression={$_.descr}}, 
                                                                                                  @{Label='ap-dn';Expression={$_.dn}},
                                                                                                  @{Label='tenant';Expression={$Tenant}},
                                                                                                  @{Label='ap-uid';Expression={$_.uid}},
                                                                                                  @{Label='ap-userdom';Expression={$_.userdom}},
                                                                                                  @{Label='ap-prio';Expression={$_.prio}},
                                                                                                  @{Label='ap-lcOwn';Expression={$_.lcOwn}}
            
    }
}


# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIAppProfile  {
	[cmdletbinding()]
	param
	(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant,

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=2)]
        [alias('ap-name')]
        $AP
    )
    # Define URL to pool
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}.json?query-target=subtree&target-subtree-class=fvAEPg" -f $global:ACIPoSHAPIC,$Tenant,$AP
    
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL -ErrorAction SilentlyContinue

    
    $EPGS = $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvAEPg.attributes | Select-Object name, prio, descr, dn

    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=children&target-subtree-class=fvAp" -f $global:ACIPoSHAPIC,$Tenant

    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    $ReturnObj = $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvAp.attributes | Where-object name -ieq $AP |
                                                                                Select-Object @{Label='ap-name';Expression={$_.name}}, 
                                                                                                @{Label='ap-alias';Expression={$_.nameAlias}}, 
                                                                                                @{Label='ap-descr';Expression={$_.descr}}, 
                                                                                                @{Label='ap-dn';Expression={$_.dn}},
                                                                                                @{Label='tenant';Expression={$Tenant}},
                                                                                                @{Label='ap-members';Expression={$EPGS}},
                                                                                                @{Label='ap-uid';Expression={$_.uid}},
                                                                                                @{Label='ap-userdom';Expression={$_.userdom}},
                                                                                                @{Label='ap-prio';Expression={$_.prio}},
                                                                                                @{Label='ap-lcOwn';Expression={$_.lcOwn}}


    return $ReturnObj   
    
}

# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIEPG  {
	[cmdletbinding()]
    param(
        [string][Parameter( Mandatory=$True,ValueFromPipelineByPropertyName)]
        $Tenant,
        
        [string][Parameter( Mandatory=$True,ValueFromPipelineByPropertyName)]
        [alias('ap-name')]
        $AP,

        [string][Parameter( Mandatory=$True,ValueFromPipelineByPropertyName)]
        $EPG
    )
    process{
        
        
        if (!($Tenant)) {
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
        }else{
            write-verbose "[$($myInvocation.MyCommand.Name)] Tenant: $Tenant" 
        }
        if (!($Ap)) {
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Application Profile specified"
        }else{
            write-verbose "[$($myInvocation.MyCommand.Name)] Ap: $Ap" 
        }
        if (!($EPG)) {
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No EPG specified"
        }else{
            write-verbose "[$($myInvocation.MyCommand.Name)] EPG: $EPG" 
        }
        #Domain
        $PollURLDom	= "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json?query-target=children&target-subtree-class=fvRsDomAtt" -f $global:ACIPoSHAPIC, $Tenant, $Ap, $EPG

        #Static Paths
        $PollURLSPath = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json?query-target=children&target-subtree-class=fvRsPathAtt" -f $global:ACIPoSHAPIC, $Tenant, $Ap, $EPG

        #Contracts
        $PollURLContract = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json?query-target=children&target-subtree-class=fvRsCons&target-subtree-class=fvRsConsIf,fvRsProtBy,fvRsProv,vzConsSubjLbl,vzProvSubjLbl,vzConsLbl,vzProvLbl,fvRsIntraEpg" -f $global:ACIPoSHAPIC, $Tenant, $Ap, $EPG

        #BridgeDomains Security AEP
        $PollURLBD = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json?query-target=subtree&target-subtree-class=fvAEPg,fvRsSecInherited,fvRtSecInherited,fvRsBd" -f $global:ACIPoSHAPIC, $Tenant, $Ap, $EPG
    
        #MISC
        $PollURLHealth = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json?rsp-subtree=full" -f $global:ACIPoSHAPIC, $Tenant, $Ap, $EPG
    
        #Subnets
        $PollURLSubnets = "https://{0}/api/node/class/uni/tn-{1}/ap-{2}/epg-{3}/fvSubnet.json?rsp-subtree=full" -f $global:ACIPoSHAPIC, $Tenant, $Ap, $EPG

        Write-Verbose "Polling Domain"
        $PollRawDom	=      Start-ACICommand -Method GET -Url $PollURLDom

        Write-Verbose "Polling Paths"
        $PollRawSPath =    Start-ACICommand -Method GET -Url $PollURLSPath 

        Write-Verbose "Polling Contracts"
        $PollRawContract = Start-ACICommand -Method GET -Url $PollURLContract

        Write-Verbose "Polling Bridge Domain"
        $PollRawBD   =     Start-ACICommand -Method GET -Url $PollURLBD

        Write-Verbose "Polling General Data"
        $PollRawHealth =   Start-ACICommand -Method GET -Url $PollURLHealth

        Write-Verbose "Polling Subnets"
        $PollRawSubnets =  Start-ACICommand -Method GET -Url $PollURLSubnets
        
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $DomRawJson	= ($PollRawDom.httpResponse	| ConvertFrom-Json).imdata
        $SPathRawJson	= ($PollRawSPath.httpResponse | ConvertFrom-Json).imdata
        $ContractRawJson = ($PollRawContract.httpResponse | ConvertFrom-Json).imdata
        $PollRAWBDJson = ($PollRawBD.httpResponse | ConvertFrom-Json).imdata
        $PollHealthJson = ($PollRawHealth.httpResponse | ConvertFrom-Json).imdata.fvAEPg.attributes
        $PollSubnetJson = ($PollRawSubnets.httpResponse | ConvertFrom-Json).imdata

        $Match = [regex]::Match($PollHealthJson.dn,'uni/tn-(?<tenant>[^/]+)/ap-(?<ap>[^/]+)/epg-(?<epg>\w+)')
        if($Null -ne $PollHealthJson  ){
            return ( [PSCustomObject] @{
                EPG = $PollHealthJson.Name
                Tenant = $Match.Groups["tenant"].value
                AP = $Match.Groups["ap"].value
                Alias = $PollHealthJson.nameAlias
                configSt = $PollHealthJson.configSt
                description = $PollHealthJson.descr
                dn = $PollHealthJson.dn
                exceptionTag = $PollHealthJson.exceptionTag
                extMngdBy = $PollHealthJson.extMngdBy
                floodOnEncap = $PollHealthJson.floodOnEncap
                fwdCtrl = $PollHealthJson.fwdCtrl
                hasMcastSource = $PollHealthJson.hasMcastSource
                isAttrBasedEPg = $PollHealthJson.isAttrBasedEPg
                isSharedSrvMsiteEPg = $PollHealthJson.isSharedSrvMsiteEPg
                lcOwn = $PollHealthJson.lcOwn
                matchT = $PollHealthJson.matchT
                modTs  = $(try{Get-Date "$($PollHealthJson.modTs)"}catch{""})
                monPolDn = $PollHealthJson.monPolDn
                nameAlias = $PollHealthJson.nameAlias
                pcEnfPref  = $PollHealthJson.pcEnfPref
                pcTag = $PollHealthJson.pcTag
                prefGrMemb = $PollHealthJson.prefGrMemb
                prio = $PollHealthJson.prio
                Scope = $PollHealthJson.Scope
                shutdown = $PollHealthJson.shutdown
                status = $PollHealthJson.status
                triggerSt = $PollHealthJson.triggerSt
                txId = $MiscPollHealthJsonData.txId
                uid = $PollHealthJson.uid

                subnets = $PollSubnetJson.fvSubnet.attributes
                

                Domains = $DomRawJson.fvRsDomAtt.attributes | Select-Object *,@{Label='name';Expression={$_.tDN -replace "uni/(l2dom|phys|vmmp-VMWare/dom)-",""}}
                Paths = $SPathRawJson.fvRsPathAtt.attributes
                Contracts =   $ContractRawJson.GetEnumerator() | ForEach-Object { $_.($($_ | Get-Member -MemberType NoteProperty).Name) }
                ContractMaster = $PollRAWBDJson.fvRsSecInherited.attributes
                BD = $PollRAWBDJson.fvRsBd.attributes
            }  )
            
        }else{
            Write-Verbose "BD Not Found"
            return $Null
        }


    
    }
    #Output
}	



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIEPGALL {
	[cmdletbinding()]
    param(
        [string]    
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant,
        
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$False,Position=2)]
        [alias('ap-name')]
        $AP
    ) 
    process {
        if("$AP" -eq ""){
            return @(foreach($AP in $(Get-ACIAppProfileAll -Tenant NIPRNET | Select-Object -ExpandProperty ap-name)){
                $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}.json?query-target=subtree&target-subtree-class=fvAEPg" -f $global:ACIPoSHAPIC, $Tenant, $Ap
                $PollRaw = Start-ACICommand -Method GET -Url $PollURL
                [PSCustomObject] $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvAEPg.attributes | Select-Object @{Label='epg';Expression={$_.name}},@{Label='ap';Expression={$AP}},@{Label='tenant';Expression={$Tenant}},@{Label='alias';Expression={$_.nameAlias}}, prio, descr, dn
            })
        }else{
            
            $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}.json?query-target=subtree&target-subtree-class=fvAEPg" -f $global:ACIPoSHAPIC, $Tenant, $Ap
            $PollRaw = Start-ACICommand -Method GET -Url $PollURL

            return $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvAEPg.attributes | Select-Object @{Label='epg';Expression={$_.name}},@{Label='ap';Expression={$AP}},@{Label='tenant';Expression={$Tenant}},@{Label='alias';Expression={$_.nameAlias}}, prio, descr, dn        

        }
    }
}

function Get-ACIBDAll {
	[cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant
    ) 
   
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }

    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=children&target-subtree-class=fvBD" -f $global:ACIPoSHAPIC, $Tenant, $Ap
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvBd.attributes | Select-Object @{Label='bd';Expression={$_.name}}, descr, dn,@{Label='tenant';Expression={$Tenant}}
}


function Get-ACITenantPolicyMLDS {
	[cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant
    ) 
   
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }
                  
    $PollURL	= "https://{0}/api/node/class/fvTenant.json?query-target-filter=or(eq(fvTenant.name,""common""),eq(fvTenant.name,""{1}""))&rsp-subtree=children&rsp-subtree-class=fvEpRetPol" -f $global:ACIPoSHAPIC, $Tenant
    Write-Verbose 'POLL:  $PollURL'
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return @(foreach($TenantData in $($($PollRaw.httpResponse | ConvertFrom-Json).imData)){
        #$TenantData
        foreach($Policy in $($TenantData.fvTenant.children.fvEpRetPol)){
            $Policy.attributes | Select-Object *, 
                                               @{Label='tenant';E={$TenantData.fvTenant.attributes.Name}},
                                               @{Label='tenant-dn';E={$TenantData.fvTenant.attributes.Name.dn}},
                                               @{Label='tenant-nameAlias';E={$TenantData.fvTenant.attributes.Name.nameAlias}},
                                               @{Label='tenant-uid';E={$TenantData.fvTenant.attributes.Name.uid}}

        }

    })
}

function Get-ACITenantPolicyEPGRetention {
	[cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant
    ) 
   
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }
                  
    $PollURL	= "https://{0}/api/node/class/fvTenant.json?query-target-filter=or(eq(fvTenant.name,""common""),eq(fvTenant.name,""{1}""))&rsp-subtree=children&rsp-subtree-class=fvEpRetPol" -f $global:ACIPoSHAPIC, $Tenant
    Write-Verbose 'POLL:  $PollURL'
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return @(foreach($TenantData in $($($PollRaw.httpResponse | ConvertFrom-Json).imData)){
        #$TenantData
        foreach($Policy in $($TenantData.fvTenant.children.fvEpRetPol)){
            $Policy.attributes | Select-Object *, 
                                               @{Label='tenant';E={$TenantData.fvTenant.attributes.Name}},
                                               @{Label='tenant-dn';E={$TenantData.fvTenant.attributes.Name.dn}},
                                               @{Label='tenant-nameAlias';E={$TenantData.fvTenant.attributes.Name.nameAlias}},
                                               @{Label='tenant-uid';E={$TenantData.fvTenant.attributes.Name.uid}}

        }

    })
}


function Get-ACITenantPolicyNetFlow {
	[cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant
    ) 
   
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }
                  
    $PollURL	= "https://{0}/api/node/class/fvTenant.json?query-target-filter=or(eq(fvTenant.name,""common""),eq(fvTenant.name,""{1}""))&rsp-subtree=children&rsp-subtree-class=netflowMonitorPol" -f $global:ACIPoSHAPIC, $Tenant
    Write-Verbose 'POLL:  $PollURL'
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return @(foreach($TenantData in $($($PollRaw.httpResponse | ConvertFrom-Json).imData)){
        #$TenantData
        foreach($Policy in $($TenantData.fvTenant.children.netflowMonitorPol)){
            $Policy.attributes | Select-Object *, 
                                               @{Label='tenant';E={$TenantData.fvTenant.attributes.Name}},
                                               @{Label='tenant-dn';E={$TenantData.fvTenant.attributes.Name.dn}},
                                               @{Label='tenant-nameAlias';E={$TenantData.fvTenant.attributes.Name.nameAlias}},
                                               @{Label='tenant-uid';E={$TenantData.fvTenant.attributes.Name.uid}}
        }

    })
}


function Get-ACITenantPolicyIGMPSnooping {
	[cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant
    ) 
   
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }
                  
    $PollURL	= "https://{0}/api/node/class/fvTenant.json?query-target-filter=or(eq(fvTenant.name,""common""),eq(fvTenant.name,""{1}""))&rsp-subtree=children&rsp-subtree-class=igmpSnoopPol" -f $global:ACIPoSHAPIC, $Tenant
    Write-Verbose 'POLL:  $PollURL'
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return @(foreach($TenantData in $($($PollRaw.httpResponse | ConvertFrom-Json).imData)){
        #$TenantData
        foreach($Policy in $($TenantData.fvTenant.children.igmpSnoopPol)){
            $Policy.attributes | Select-Object *, 
                                               @{Label='tenant';E={$TenantData.fvTenant.attributes.Name}},
                                               @{Label='tenant-dn';E={$TenantData.fvTenant.attributes.Name.dn}},
                                               @{Label='tenant-nameAlias';E={$TenantData.fvTenant.attributes.Name.nameAlias}},
                                               @{Label='tenant-uid';E={$TenantData.fvTenant.attributes.Name.uid}}
        }

    })
}


function Get-ACITenantPolicyNeighborDiscovery {
	[cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant
    ) 
   
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }
                  
    $PollURL	= "https://{0}/api/node/class/fvTenant.json?query-target-filter=or(eq(fvTenant.name,""common""),eq(fvTenant.name,""{1}""))&rsp-subtree=children&rsp-subtree-class=ndIfPol" -f $global:ACIPoSHAPIC, $Tenant
    Write-Verbose 'POLL:  $PollURL'
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return @(foreach($TenantData in $($($PollRaw.httpResponse | ConvertFrom-Json).imData)){
        #$TenantData
        foreach($Policy in $($TenantData.fvTenant.children.ndIfPol)){
            $Policy.attributes | Select-Object *, 
                                               @{Label='tenant';E={$TenantData.fvTenant.attributes.Name}},
                                               @{Label='tenant-dn';E={$TenantData.fvTenant.attributes.Name.dn}},
                                               @{Label='tenant-nameAlias';E={$TenantData.fvTenant.attributes.Name.nameAlias}},
                                               @{Label='tenant-uid';E={$TenantData.fvTenant.attributes.Name.uid}}
        }

    })
}
#
function Get-ACIInfrastructureSettings {
	[cmdletbinding()]
    param() 
   

    $PollURL	= "https://{0}/api/node/class/infraSetPol.json" -f $global:ACIPoSHAPIC
    Write-Verbose 'POLL:  $PollURL'
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imData.infraSetPol.attributes
}



function Get-ACITenantPolicyEPGMon {
	[cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant
    ) 
   
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }
                  
    $PollURL	= "https://{0}/api/node/class/fvTenant.json?query-target-filter=or(eq(fvTenant.name,""common""),eq(fvTenant.name,""{1}""))&rsp-subtree=children&rsp-subtree-class=monEPGPol" -f $global:ACIPoSHAPIC, $Tenant
    Write-Verbose 'POLL:  $PollURL'
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return @(foreach($TenantData in $($($PollRaw.httpResponse | ConvertFrom-Json).imData)){
        #$TenantData
        foreach($Policy in $($TenantData.fvTenant.children.monEPGPol)){
            $Policy.attributes | Select-Object *, 
                                               @{Label='tenant';E={$TenantData.fvTenant.attributes.Name}},
                                               @{Label='tenant-dn';E={$TenantData.fvTenant.attributes.Name.dn}},
                                               @{Label='tenant-nameAlias';E={$TenantData.fvTenant.attributes.Name.nameAlias}},
                                               @{Label='tenant-uid';E={$TenantData.fvTenant.attributes.Name.uid}}
        }

    })
}

function Get-ACITenantPolicyMonitorAll {
	[cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant
    ) 
   
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }
                  
    $PollURL	= "https://{0}/api/node/class/fvTenant.json?query-target-filter=or(eq(fvTenant.name,""common""),eq(fvTenant.name,""{1}""))&rsp-subtree=children&rsp-subtree-class=monEPGPol" -f $global:ACIPoSHAPIC, $Tenant
    Write-Verbose 'POLL:  $PollURL'
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return @(foreach($TenantData in $($($PollRaw.httpResponse | ConvertFrom-Json).imData)){
        #$TenantData
        foreach($Policy in $($TenantData.fvTenant.children.monEPGPol)){
            $Policy.attributes | Select-Object *, 
                                               @{Label='tenant';E={$TenantData.fvTenant.attributes.Name}},
                                               @{Label='tenant-dn';E={$TenantData.fvTenant.attributes.Name.dn}},
                                               @{Label='tenant-nameAlias';E={$TenantData.fvTenant.attributes.Name.nameAlias}},
                                               @{Label='tenant-uid';E={$TenantData.fvTenant.attributes.Name.uid}}
        }

    })
}


function Get-ACITenantPolicyFirstHopBD {
	[cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant
    ) 
   
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }
                  
    $PollURL	= "https://{0}/api/node/class/fvTenant.json?query-target-filter=or(eq(fvTenant.name,""common""),eq(fvTenant.name,""{1}""))&rsp-subtree=children&rsp-subtree-class=fhsBDPol" -f $global:ACIPoSHAPIC, $Tenant
    Write-Verbose 'POLL:  $PollURL'
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    return @(foreach($TenantData in $($($PollRaw.httpResponse | ConvertFrom-Json).imData)){
        #$TenantData
        foreach($Policy in $($TenantData.fvTenant.children.fhsBDPol)){
            $Policy.attributes | Select-Object *, 
                                               @{Label='tenant';E={$TenantData.fvTenant.attributes.Name}},
                                               @{Label='tenant-dn';E={$TenantData.fvTenant.attributes.Name.dn}},
                                               @{Label='tenant-nameAlias';E={$TenantData.fvTenant.attributes.Name.nameAlias}},
                                               @{Label='tenant-uid';E={$TenantData.fvTenant.attributes.Name.uid}}
        }

    })
}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIBD {
	[cmdletbinding()] 
    param (
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant,

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=2)]
        $BD
    ) 
    
    
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}.json?" -f $global:ACIPoSHAPIC, $Tenant, $BD
   

    $PollUrlL3	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}.json?query-target=children&target-subtree-class=fvRsBDToOut" -f $global:ACIPoSHAPIC, $Tenant, $BD
    
    $PollURLSubnet	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}.json?query-target=children&target-subtree-class=fvSubnet" -f $global:ACIPoSHAPIC, $Tenant, $BD

    $PollRaw	   = Start-ACICommand -Method GET -Url $PollURL
    $PollRawL3     = Start-ACICommand -Method GET -Url $PollUrlL3
    $PollRawSubnet = Start-ACICommand -Method GET -Url $PollURLSubnet
    
    #Poll the URL via HTTP then convert to PoSH objects from JSON
    $OutRawJson	        =	$($PollRaw.httpResponse	|	ConvertFrom-Json).imdata.fvBd.attributes
    $OutRawJsonL3	    =	$($PollRawL3.httpResponse	|	ConvertFrom-Json).imdata.fvRsBDToOut.attributes
    $SubnetsJson	    =	$($PollRawSubnet.httpResponse	|	ConvertFrom-Json).imdata.fvSubnet.attributes

    return [PSCustomObject]@{
        name = $OutRawJson.name
        descr = $OutRawJson.descr
        mtu = $OutRawJson.mtu
        limitIpLearnToSubnets = $OutRawJson.limitIpLearnToSubnets
        arpFlood = $OutRawJson.arpFlood
        dn = $OutRawJson.dn
        raw = $OutRawJson
        L3Outs = $OutRawJsonL3
        Subnets = $SubnetsJson | Select-Object ip,scope
        DHCP = get-ACIBDDHCPPolicy -Tenant $Tenant -bd $BD

    }
}


function Get-ACIUsageBD {
    [cmdletbinding()]
    param(
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        $Tenant,

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=2)]
        $BD
    )

    process{
        

        $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}.json?" -f $global:ACIPoSHAPIC, $Tenant, $BD
        $PollNWIF   = "{0}{1}" -f $PollURL, 'rsp-subtree-include=full-deployment&target-path=BDToNwIf'
    
        $PollRln    = "{0}{1}" -f $PollURL, 'query-target=children&target-subtree-class=relnFrom'

        $ResultNWIF = Start-ACICommand -Method GET -Url $PollNWIF 
        $ResultDependencies = Start-ACICommand -Method GET -Url $PollRln 
        Write-Verbose "BD Name: $BD"
        $GLOBAL:DATA = ($ResultDependencies.httpResponse | ConvertFrom-Json).imdata
        write-verbose "Data: $(($ResultDependencies.httpResponse | ConvertFrom-Json).imdata  | Out-string)"
        $ReturnObject = [ordered]@{
            bd = ($ResultNWIF.httpResponse | ConvertFrom-Json).imdata.fvBD.attributes
            dependencies = @(
                if(($ResultDependencies.httpResponse | ConvertFrom-Json).imdata.count -gt 0){

                    foreach($property in (($ResultDependencies.httpResponse | ConvertFrom-Json).imdata | get-member -MemberType NoteProperty | Select-Object -ExpandProperty Name)){
                        foreach($Item in ($ResultDependencies.httpResponse | ConvertFrom-Json).imdata.$property){
                            [PSCustomObject]@{
                                $Property =  $Item.attributes
                            }
                        }
                    }
                }
            )
        }

        $ReturnObject.bd | Add-member -MemberType NoteProperty -Name bd -Value $BD
        $ReturnObject.bd | Add-member -MemberType NoteProperty -Name tenant -Value $Tenant

        return [PSCustomObject] $ReturnObject

    }
}


# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIVRFAll {
	[cmdletbinding()] 
    param (
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        [Alias('Name')]
        $Tenant
    ) 
    
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=children&target-subtree-class=fvCtx" -f $global:ACIPoSHAPIC, $Tenant
    $PollRaw	   = Start-ACICommand -Method GET -Url $PollURL

    Write-Output  -InputObject $($($PollRaw.httpResponse | ConvertFrom-Json).imdata.fvCtx.attributes | Select-Object name, descr, bdEnforcedEnable, pcEnfDir, pcEnfPref, dn )
}


# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIVRF {
	[cmdletbinding()] 
    param (
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True)]
        [string]$Tenant,
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True)]
        [string]$VRF
    ) 
    
    
    $PollURLMain = "https://{0}/api/node/mo/uni/tn-{1}/ctx-{2}.json?rsp-subtree-include=health" -f $global:ACIPoSHAPIC,$Tenant,$VRF
    Write-Verbose "Main Polling URL: $PollURLMain"
    $PollURLFeatures = "https://{0}/api/node/mo/uni/tn-{1}/ctx-{2}.json?query-target=subtree" -f $global:ACIPoSHAPIC,$Tenant,$VRF
    Write-Verbose "VRF Subfeature Polling URL: $PollURLFeatures"
    

    $PollMain = Start-ACICommand -Method GET -Url $PollURLMain
    $MainJson = ($PollMain.httpResponse | ConvertFrom-Json).imData.fvCtx.Attributes

    $PollFeatures = Start-ACICommand -Method GET -Url $PollURLFeatures
    $PollFeaturesJson  = ($PollFeatures.httpResponse | ConvertFrom-Json).imData

    return [PSCustomObject]@{
        vrf = $MainJson.name
        annotation = $MainJson.annotation
        bdEnforcedEnable = $MainJson.bdEnforcedEnable
        childAction = $MainJson.childAction
        descr = $MainJson.descr
        dn = $MainJson.dn
        extMngdBy = $MainJson.extMngdBy
        ipDataPlaneLearning = $MainJson.ipDataPlaneLearning
        knwMcastAct = $MainJson.knwMcastAct
        lcOwn = $MainJson.lcOwn
        modTs = $(Get-Date $MainJson.modTS)
        monPolDn = $MainJson.monPolDn
        name = $MainJson.name
        nameAlias = $MainJson.nameAlias
        ownerKey = $MainJson.ownerKey
        ownerTag = $MainJson.ownerTag
        pcEnfDir = $MainJson.pcEnfDir
        pcEnfDirUpdated = $MainJson.pcEnfDirUpdated
        pcEnfPref = $MainJson.pcEnfPref
        pcTag = $MainJson.pcTag
        scope = $MainJson.scope
        seg = $MainJson.seg
        status = $MainJson.status
        uid = $MainJson.uid
        bgpRtTarget = $PollFeaturesJson.bgpRtTarget.attributes
        bgpRtTargetP = $PollFeaturesJson.bgpRtTargetP.attributes
        dnsLbl = $PollFeaturesJson.dnsLbl.attributes
        fvRsBgpCtxPol = $PollFeaturesJson.fvRsBgpCtxPol.attributes
        fvRsCtxToBgpCtxAfPol = $PollFeaturesJson.fvRsCtxToBgpCtxAfPol.attributes
        fvRsCtxToEigrpCtxAfPol = $PollFeaturesJson.fvRsCtxToEigrpCtxAfPol.attributes
        fvRsCtxToEpRet = $PollFeaturesJson.fvRsCtxToEpRet.attributes
        fvRsCtxToExtRouteTagPol = $PollFeaturesJson.fvRsCtxToExtRouteTagPol.attributes
        fvRsCtxToOspfCtxPol = $PollFeaturesJson.fvRsCtxToOspfCtxPol.attributes
        fvRsOspfCtxPol = $PollFeaturesJson.fvRsOspfCtxPol.attributes
        fvRsVrfValidationPol = $PollFeaturesJson.fvRsVrfValidationPol.attributes
        fvRtCtx = $PollFeaturesJson.fvRtCtx.attributes
        vzAny = $PollFeaturesJson.vzAny.attributes
        fvCtx = $PollFeaturesJson.fvCtx.attributes
        
    }
    
}


Function Get-ACIL3OutExternalNetworks {
        [cmdletbinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName,Mandatory)]
        [string]$Tenant,

        [Parameter(ValueFromPipelineByPropertyName,Mandatory)]
        [string]$L3OutName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$ExternalNetworkName=""

    )
    $PollURL = 'https://{0}/api/node/mo/uni/tn-{1}/out-{2}.json?query-target=children&target-subtree-class=l3extInstP&query-target-filter=and(and(not(wcard(l3extInstP.dn,"__ui_")),not(wcard(l3extInstP.annotation,"shadow:yes")),not(wcard(l3extInstP.annotation,"system-hidden:yes"))),not(wcard(l3extInstP.dn,"^.*/instP-__int_.*")))&query-target=subtree&target-subtree-class=l3extSubnet&query-target-filter=not(wcard(l3extSubnet.dn,"__ui_"))&rsp-subtree=full&rsp-subtree-class=l3extRsSubnetToProfile,l3extRsSubnetToRtSumm&target-subtree-class=fvRsCons&target-subtree-class=fvRsConsIf,fvRsProtBy,fvRsProv,vzConsSubjLbl,vzProvSubjLbl,vzConsLbl,vzProvLbl,fvRsIntraEpg' -f $Global:ACIPoSHAPIC,$Tenant,$L3OutName,$ExternalNetworkName
    


    $PollReponse = Start-ACICommand -url $PollURL -encoding 'application/json' -Method GET
    $IMData = $($PollReponse.httpResponse | ConvertFrom-Json).imdata 


    $Data = foreach($Row in $IMdata.l3extInstP ){
        if($Null -ne $Row){
            $RowData = $Row.attributes #| Select-Object *, {Label='Subnets';Expression={$IMData.l3extSubnet.attributes | Where-Object {$_.} }}
            $RowData | Add-Member -NotePropertyName "Subnets" -NotePropertyValue $($IMData.L3extSubnet.attributes | Where-Object {$_.DN -match "instP-$($RowData.name)"}) 
            $RowData | Add-Member -NotePropertyName "CtxProvider" -NotePropertyValue $($IMData.fvRsProv.attributes | Where-Object {$_.DN -match "instP-$($RowData.name)"}) 
            $RowData | Add-Member -NotePropertyName "CtxConsumer" -NotePropertyValue $($IMData.fvRsCons.attributes | Where-Object {$_.DN -match "instP-$($RowData.name)"}) 
            $RowData
        }
    }
    if($ExternalNetworkName -ne ''){
        return $Data | Where-Object {$_.name -imatch $ExternalNetworkName}
    }else{
        return $Data
    }
}

function Remove-ACIL3OutExternalSubnet {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        $DN
    )

    Remove-ACIObjectByDN -DN $DN -VariableName 'l3extSubnet'
}


function Get-ACIL3OutExternalNetworkSubnets{
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName,Mandatory)]
        [string]$Tenant,

        [Parameter(ValueFromPipelineByPropertyName,Mandatory)]
        [string]$L3OutName,

        [Parameter(ValueFromPipelineByPropertyName,Mandatory)]
        [string]$ExternalNetworkName

    )
    $PollURL = 'https://{0}/api/node/mo/uni/tn-{1}/out-{2}/instP-{3}.json?query-target=subtree&target-subtree-class=l3extSubnet&query-target-filter=not(wcard(l3extSubnet.dn,"__ui_"))&rsp-subtree=full&rsp-subtree-class=l3extRsSubnetToProfile,l3extRsSubnetToRtSumm' -f $GLobal:ACIPoSHAPIC,$Tenant,$L3OutName,$ExternalNetworkName

    $PollReponse = Start-ACICommand -url $PollURL -encoding 'application/json' -Method GET

    return ($PollReponse.httpResponse | ConvertFrom-json).imdata.l3extSubnet.Attributes

}

# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIL3outAll {
	[cmdletbinding()] 
    param (
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        [string]$Tenant
    ) 

    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=children&target-subtree-class=l3extOut" -f $global:ACIPoSHAPIC,$Tenant
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.l3extOut.attributes| Select-Object name, enforceRtctrl, descr, dn
}

# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIL3out {
	[cmdletbinding()] 
    param (
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        [string]$Tenant,
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=2)]
        [string]$L3out
    ) 
   
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/out-{2}.json?query-target=children&target-subtree-class=l3extRsEctx" -f $global:ACIPoSHAPIC,$Tenant,$L3Out
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.l3extRsEctx.attributes | Select-Object @{Label="L3O";Expression={$L3Out}},@{Label="Tenant";Expression={$Tenant}},* #tRn, tnFvCtxName, descr, dn
}


# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricPhysicalDomain {
    [cmdletbinding()]

    #Define URL to pool
    $PollURL = "https://{0}/api/node/mo/uni.json?query-target=subtree&target-subtree-class=physDomP" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.physDomP.attributes | Select-Object @{Label="physDomain";Expression={$_.name}},*
}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricAEEP {
    [cmdletbinding()] 

    $PollURL = "https://{0}/api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraAttEntityP" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.infraAttEntityP.attributes | Select-Object @{Label="aep";Expression={$_.name}},*
    
}


# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricPortLinkLevel {
    [cmdletbinding()] 

    $PollURL = "https://{0}/api/node/class/fabricHIfPol.json?query-target-filter=not(wcard(fabricHIfPol.dn,""__ui""))" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.fabricHIfPol.attributes 
}

# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricPortCDP {
    [cmdletbinding()]     

    $PollURL = "https://{0}/api/node/class/cdpIfPol.json?query-target-filter=not(wcard(cdpIfPol.dn,""__ui""))" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.cdpIfPol.attributes 
}	


# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricPortLLDP	{	
    [cmdletbinding()] 
    
    $PollURL = "https://{0}/api/node/mo/uni/infra.json?query-target=children&target-subtree-class=lldpIfPol&query-target-filter=not(wcard(lldpIfPol.dn,""__ui""))" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.lldpIfPol.attributes 
}


# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricPortLACP {
    [cmdletbinding()]  
    
    $PollURL = "https://{0}/api/node/class/lacpLagPol.json?query-target-filter=not(wcard(lacpLagPol.dn,""__ui""))" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.lacpLagPol.attributes 
}


# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricSwitchLeaf {
    [cmdletbinding()] 
    
    $PollURL = "https://{0}/api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraNodeP&query-target-filter=not(wcard(infraNodeP.name,""__ui_""))" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.infraNodeP.attributes 
}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricVLANPoolAll {
    [cmdletbinding()] 

    $PollURL = "https://{0}/api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=fvnsVlanInstP" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.fvnsVlanInstP.attributes 
}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricLeafAccessPolicyAll {
    [cmdletbinding()] 

    $PollURL = "https://{0}/api/node/mo/uni/infra/funcprof.json?query-target=subtree&target-subtree-class=infraAccPortGrp&query-target-filter=not(wcard(infraAccPortGrp.dn,""__ui_""))" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.infraAccPortGrp.attributes 
}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricLeafAccessPolicy  {
    [cmdletbinding()] 
    param(
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true)]
        [string]$LeafAccessPolicy
    )
   

    $PollURL = "https://{0}/api/node/mo/uni/infra/funcprof/accportgrp-{1}.json" -f $global:ACIPoSHAPIC, $LeafAccessPolicy
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.infraAccPortGrp.attributes 
}

function Get-ACIFabricLeafVPCPolicyAll  {
    [cmdletbinding()] 
    param(
    )
   

    $PollURL = "https://{0}/api/node/class/infraAccBndlGrp.json" -f $global:ACIPoSHAPIC
    Write-Verbose "Poll URL: $PollURL"
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    Write-Verbose $PollRaw
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.infraAccBndlGrp.attributes | Select-Object name, nameAlias, annotation, descr, childAction, dn, extMngdBy, lagT, lcOwn, modTs, monPolDn, ownerKey, ownerTag, status, uid, userdom

}

function Get-ACIFabricLeafVPCPolicy  {
    [cmdletbinding()] 
    param(
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true)]
        [string]$VPCName
    )

    #Build URL
    $PollURL = "https://{0}/api/node/mo/uni/infra/funcprof/accbundle-{1}.json?query-target=self" -f $global:ACIPoSHAPIC, $VPCName
    Write-Verbose "Poll URL: $PollURL"

    #Execute Query
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    Write-Verbose "Poll Raw: $($PollRaw.HttpResponse -replace "Forbidden$",'')`r`n`r`n"
#    $Global:PollRaw = $PollRaw

    #Create Beginning Object others will be attached to.
    $PrimaryObject = $($PollRaw.httpResponse  -replace "Forbidden$",'' | ConvertFrom-Json).imdata.infraAccBndlGrp.Attributes #.infraAccPortGrp.attributes 

    #Generate List of Subtrees to append
    [Hashtable] $SubTrees = @{'infraRsAttEntP'='AEP' #AEP
                           'infraRsCdpIfPol'='CDP' #CDP
                           'infraRsLldpIfPol'='LLDP' #LLDP
                           'infraRsHIfPol'='LinkLevelPolicy' #LLP
                           'infraRsLacpPol'='PortChannel' #PortChannel
                           'infraRsCoppIfPol'='COPP' #COPP
                           'infraRsQosEgressDppIfPol'='EgressDPP' #EgressDPP
                           'infraRsLinkFlapPol'='LinkFlap' #Link Flap
                           'infraRsQosIngressDppIfPol'='IngressDPP' #Ingress
                           'infraRsFcIfPol' ='FibreChannel' #FC
                           'infraRsL2IfPol' ='L2Interface' #L2 Interface
                           'infraRsQosLlfcIfPol'='LinkLevelFlowControl' #Link Level Flow
                           'infraRsMacsecIfPol'="MACSec" #MACSEC
                           'infraRsMcpIfPol'="MCP" #MCP
                           'infraRsMonIfInfraPol'="MonitoringPol" #MONITOR
                           'infraRsL2PortSecurityPol'="PortSecurity" #Port Security
                           'infraRsQosPfcIfPol'="PriorityFlowControl" #Priority Flow Control
                           'infraRsStormctrlIfPol'="StormControl" #Slow Drain
                           'infraRsQosSdIfPol'="SlowDrain"#Storm Control
                           'infraRsStpIfPol'="SpanningTree" #STP
                        }

    
    #Get Subtree Data and append to record
    foreach($SubTree in $Subtrees.Keys){
        $PollURL = "https://{0}/api/node/mo/uni/infra/funcprof/accbundle-{1}.json?query-target=children&target-subtree-class={2}" -f $global:ACIPoSHAPIC, $VPCName, $SubTree
        $PollRaw = Start-ACICommand -Method GET -Url $PollURL
        $PrimaryObject | Add-Member -MemberType NoteProperty -Name $SubTrees[$Subtree] -Value $($($PollRaw.httpResponse  -replace "Forbidden$",'' | ConvertFrom-Json).imdata.$Subtree.Attributes )
   

    }




    return $PrimaryObject | ConvertTo-Json -Depth 100 | ConvertFrom-Json

}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIAAASecDomain {
    [cmdletbinding()] 
    
    
    $PollURL = "https://{0}/api/node/class/aaaDomain.json?order-by=aaaDomain.name|asc" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.aaaDomain.attributes 
}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIAAASecRole {
    [cmdletbinding()] 
    
    $PollURL = "https://{0}/api/node/class/aaaRole.json?query-target-filter=ne(aaaRole.name,""read-only"")&order-by=aaaRole.name" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.aaaRole.attributes 
}




# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIAAALocalUsers {
    [cmdletbinding()] 
    
    $PollURL = "https://{0}/api/node/class/aaaUser.json?order-by=aaaUser.name" -f $global:ACIPoSHAPIC
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.aaaUser.attributes 
}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACISecurityContractAll  {
    [cmdletbinding()] 
    param (
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=1)]
        [string]$Tenant
    )

    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=children&target-subtree-class=vzBrCP" -f $global:ACIPoSHAPIC, $Tenant
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.vzBrCP.attributes 
     
}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACISecurityContract  {
    [cmdletbinding()] 
    param (
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=1)]
        $Tenant, 

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=2)]
        $Contract
    )
   
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=children&target-subtree-class=vzBrCP" -f $global:ACIPoSHAPIC, $Tenant
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.vzBrCP.attributes     
}

function Get-ACISecurityContractFilterAll {
    [cmdletbinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $Tenant,

        [switch]
        $IncludeSubtree
    )
    
    $Prefix='flt'

    if($IncludeSubtree){
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=subtree&target-subtree-class=vzFilter,vzEntry,vzRsFwdRFltPAtt,vzRsRevRFltPAtt,vzRtSubjFiltAtt" -f $global:ACIPoSHAPIC, $Tenant
    }else{
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=subtree&target-subtree-class=vzFilter" -f $global:ACIPoSHAPIC, $Tenant 
    }
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    $RawData = $($PollRaw.httpResponse | ConvertFrom-Json).imdata

    $Filters = $RawData.vzFilter.attributes

    if($IncludeSubtree){
        foreach($Filter in $Filters){
            $Filter | Add-Member -MemberType NoteProperty -Name "$Prefix-tenant" -Value $Tenant
            $Filter | Add-Member -Name 'vzEntry' -MemberType NoteProperty -Value @($RawData.vzEntry.attributes | Where-Object { $_.dn -match [regex]::escape($Filter.dn)})
            $Filter | Add-Member -Name 'vzRsFwdRFltPAtt' -MemberType NoteProperty -Value @($RawData.vzRsFwdRFltPAtt.attributes | Where-Object { $_.dn -match [regex]::escape($Filter.dn)})
            $Filter | Add-Member -Name 'vzRsRevRFltPAtt' -MemberType NoteProperty -Value @($RawData.vzRsRevRFltPAtt.attributes | Where-Object { $_.dn -match [regex]::escape($Filter.dn)})
            $Filter | Add-Member -Name 'vzRtSubjFiltAtt' -MemberType NoteProperty -Value @($RawData.vzRtSubjFiltAtt.attributes | Where-Object { $_.dn -match [regex]::escape($Filter.dn)})
        }
    }else{
        foreach($Filter in $Filters){
            $Filter | Add-Member -MemberType NoteProperty -Name "$Prefix-tenant" -Value $Tenant
            $Filter | Add-Member -Name 'vzEntry' -MemberType NoteProperty -Value @()
            $Filter | Add-Member -Name 'vzRsFwdRFltPAtt' -MemberType NoteProperty -Value @()
            $Filter | Add-Member -Name 'vzRsRevRFltPAtt' -MemberType NoteProperty -Value @()
            $Filter | Add-Member -Name 'vzRtSubjFiltAtt' -MemberType NoteProperty -Value @()
        
        }      
    }

    return $Filters 
}


function Get-ACISecurityContractFilter {
    [cmdletbinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $Tenant,

        [string]
        [Parameter(Mandatory)]
        $FilterName,

        [switch]
        $IncludeSubtree
    )
    
    if($IncludeSubtree){
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/flt-{2}.json?rsp-subtree=full" -f $global:ACIPoSHAPIC, $Tenant,$FilterName #target-subtree-class=vzEntry
    }else{
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/flt-{2}.json?rsp-subtree=no" -f $global:ACIPoSHAPIC, $Tenant,$FilterName #target-subtree-class=vzEntry
    
    }
    
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL -Verbose:$VerbosePreference
    $RawData = $($PollRaw.httpResponse | ConvertFrom-Json).imdata
    $ReturnObject = @($RawData.vzFilter.attributes)

    $Children=@($RawData.vzFilter.children)
    $ReturnObject | Add-Member -Name 'vzEntry' -MemberType NoteProperty -Value @($Children.vzEntry.attributes)
    $ReturnObject | Add-Member -Name 'vzRsFwdRFltPAtt' -MemberType NoteProperty -Value @($Children.vzRsFwdRFltPAtt.attributes)
    $ReturnObject | Add-Member -Name 'vzRsRevRFltPAtt' -MemberType NoteProperty -Value @($Children.vzRsRevRFltPAtt.attributes)
    $ReturnObject | Add-Member -Name 'vzRtSubjFiltAtt' -MemberType NoteProperty -Value @($Children.vzRtSubjFiltAtt.attributes)

    return $ReturnObject | Select-Object *,@{Label='tenant';Expression={$Tenant}}
}

function Get-ACISecurityContractFilterEntries {
    [cmdletbinding()]
    param(
        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [alias('flt-tenant')]
        $Tenant,
        
        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [alias('flt-name','name')]
        $FilterName
    )

    $Prefix = 'rule'

    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/flt-{2}.json?query-target=children&target-subtree-class=vzEntry" -f $global:ACIPoSHAPIC, $Tenant, $FilterName
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL

    $ReturnObject = $($PollRaw.httpResponse | ConvertFrom-Json).imdata.vzEntry.attributes     

    foreach($Object in  $ReturnObject){
        $Object | Add-Member -MemberType NoteProperty -Name "$Prefix-tenant" -Value $Tenant
        $Object | Add-Member -MemberType NoteProperty -Name "$Prefix-filtername" -Value $FilterName
        #foreach($PropertyName in $($Object| Get-member -MemberType NoteProperty  | Select-Object -ExpandProperty name)){
        #    $Object | Add-Member -MemberType NoteProperty -Name "$Prefix-$PropertyName" -Value $Object.$PropertyName 
        #    $Object.PSObject.Properties.remove($PropertyName)
        #}
    }
    return $ReturnObject  
}


###################################################################################################################
## Create functions
###################################################################################################################

function New-ACISecurityContractFilter {
    [cmdletbinding()]
    param(
        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [alias('flt-tenant')]
        $Tenant,
        
        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [alias('flt-name','name')]
        [validatePattern('^\w[\w`-]+$')]
        $FilterName,
        
        [string]
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias('flt-alias')]
        [validatePattern('^\w[\w`-]+$')]
        $Alias="",
                
        [string]
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias('flt-descr','descr')]
        $Description=""

    )

    #Define URL to pool
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/flt-{2}.json" -f $global:ACIPoSHAPIC, $Tenant, $FilterName

    $PollBody = [ordered]@{
        vzFilter = [ordered]@{
            attributes = @{
                dn = "uni/tn-$Tenant/flt-$FilterName"
                name = $FilterName
                nameAlias = $Alias
                descr = $Description
                rn = "flt-$FilterName"
                status = "created,modified"
            }
            children = [system.collections.arraylist]@()
        }
    }
    
    $JSONBody = $PollBody | ConvertTo-Json -Compress

    $Response = Start-ACICommand -Method POST -Url $PollURL -Encoding 'application/json' -PostData $JSONBody
    
    if($Response.httpcode -ge 200 -and $Response.httpcode -lt 300 ){
        return [PSCustomObject]@{
            status = 'success'
            dn = $PollBody.vzFilter.attributes.dn
            response = $Response
        }
    }else{
        return [PSCustomObject]@{
            status = 'failed'
            dn = $PollBody.vzFilter.attributes.dn
            response = $Response
        }
    }
}



function New-ACISecurityContractFilterEntry {
    [cmdletbinding(DefaultParameterSetName='Default')]
    param(
        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [alias('flt-tenant')]
        $Tenant,
        
        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [alias('flt-name','name')]
        [validatePattern('^\w[\w`-]+$')]
        $FilterName,

        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [alias('rule-name')]
        [validatePattern('^\w[\w`-]+$')]
        $RuleName,

        
        [string]
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias('rule-alias')]
        [validatePattern('^\w[\w`-]+$')]
        $RuleAlias,

        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [validateSet('ip','ipv6','ipv4','mpls_ucast','unspecified','trill','arp','fcoe','mac_security')]
        $EtherType,

        [string]
        [Parameter(ValueFromPipelineByPropertyName)]
        [validateSet('unspecified','reply','req')]
        $ArpType='unspecified',
        
        [string]
        [Parameter(ValueFromPipelineByPropertyName)]
        [validateSet('eigrp','egp','icmp','icmpv6','igmp','igp','l2tp','ospfigp','pim','tcp','udp','unspecified')]
        $IPProtocol='unspecified',

        [switch]
        [Parameter(ValueFromPipelineByPropertyName)]
        $MatchFragmentsOnly,

        
        [switch]
        [Parameter(ValueFromPipelineByPropertyName)]
        $Stateful,

        [switch]
        [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='RESET')]
        $Established,

        [switch]
        [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='NotEstablished')]
        $Synchronize,

        [switch]
        [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='NotEstablished')]
        $Acknowledgment,

        [switch]
        [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='NotEstablished')]
        $Reset,

        [switch]
        [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='NotEstablished')]
        $Finish,

        [Int32]
        [Parameter(ValueFromPipelineByPropertyName)]
        [validateScript({
            if($_ -lt 0 -or $_ -gt 65535){
                throw "The Value of SourceFromPort is not between 1-65535"
            }else{$True}
        })]
        $SourceFromPort=0,
        
        [Int32]
        [Parameter(ValueFromPipelineByPropertyName)]
        [validateScript({
            if($_ -lt 0 -or $_ -gt 65535){
                throw "The Value of SourceToPort is not between 1-65535"
            }else{$True}
        })]
        $SourceToPort=0,
        
        [Int32]
        [Parameter(ValueFromPipelineByPropertyName)]
        [validateScript({
            if($_ -lt 0 -or $_ -gt 65535){
                throw "The Value of DestinationFromPort is not between 1-65535"
            }else{$True}
        })]
        $DestinationFromPort=0,
        
        [Int32]
        [Parameter(ValueFromPipelineByPropertyName)]
        [validateScript({
            if($_ -lt 0 -or $_ -gt 65535){
                throw "The Value of DestinationToPort is not between 1-65535"
            }else{$True}
        })]
        $DestinationToPort=0
    )

    #Define URL to pool
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/flt-{2}/e-{3}.json" -f $global:ACIPoSHAPIC, $Tenant, $FilterName, $RuleName

    

    [string[]] $TCPRules = @()
    if($Finish ){ $TCPRules += 'fin' }
    if($Acknowledgment){ $TCPRules += 'ack' }
    if($Synchronize){ $TCPRules += 'syn' }
    if($Reset){ $TCPRules += 'rst' }
    if($Established){ $TCPRules += 'est' }
#rst,ack,syn,fin
    $PollBody = [ordered]@{
        vzEntry = [ordered]@{
            attributes = @{
                dn = "uni/tn-$Tenant/flt-$FilterName/e-$RuleName"
                applyToFrag=if($MatchFragmentsOnly){'true'}else{'false'}
                name = $RuleName
                nameAlias = $RuleAlias
                etherT = $EtherType
                arpOpc = $ArpType
                prot =  $IPProtocol
                stateful = if($Stateful){'true'}else{'false'}
                tcpRules = $TCPRules -join ','
                sFromPort = "$SourceFromPort"
                sToPort   = "$SourceToPort"
                dFromPort = "$DestinationFromPort"
                dToPort   = "$DestinationToPort"
                status = "created,modified"
                rn = "e-$RuleName"
            }
            children = [system.collections.arraylist]@()
        }
    }



        if($EtherType -iin $('mpls_ucast','unspecified','trill','fcoe','mac_security')){
            $PollBody.vzEntry.attributes.Remove('applyToFrag')
            $PollBody.vzEntry.attributes.Remove('prot')
            $PollBody.vzEntry.attributes.Remove('arpOpc')
            $PollBody.vzEntry.attributes.Remove('stateful')
            $PollBody.vzEntry.attributes.Remove('tcpRules')
            $PollBody.vzEntry.attributes.Remove('sFromPort')
            $PollBody.vzEntry.attributes.Remove('sToPort')
            $PollBody.vzEntry.attributes.Remove('dFromPort')
            $PollBody.vzEntry.attributes.Remove('dToPort')

        }elseif($EtherType -iin $('arp')){
            $PollBody.vzEntry.attributes.Remove('applyToFrag')
            if($ArpType -eq 'unspecified' -or "$ArpType" -eq ''){
                $PollBody.vzEntry.attributes.Remove('arpOpc')
            }
            $PollBody.vzEntry.attributes.Remove('prot')
            $PollBody.vzEntry.attributes.Remove('stateful')
            $PollBody.vzEntry.attributes.Remove('tcpRules')
            $PollBody.vzEntry.attributes.Remove('sFromPort')
            $PollBody.vzEntry.attributes.Remove('sToPort')
            $PollBody.vzEntry.attributes.Remove('dFromPort')
            $PollBody.vzEntry.attributes.Remove('dToPort')
        }elseif($EtherType -iin $('ip','ipv4','ipv6') -and $IPProtocol -iin 'eigrp','egp','icmp','icmpv6','igmp','igp','l2tp','ospfigp','pim','unspecified' ){
            if($IPProtocol -eq 'unspecified'){
                $PollBody.vzEntry.attributes.Remove('prot')
            }
            if(!$MatchFragmentsOnly){
                $PollBody.vzEntry.attributes.Remove('applyToFrag')
            }
            $PollBody.vzEntry.attributes.Remove('arpOpc')
            $PollBody.vzEntry.attributes.Remove('stateful')
            $PollBody.vzEntry.attributes.Remove('tcpRules')
            $PollBody.vzEntry.attributes.Remove('sFromPort')
            $PollBody.vzEntry.attributes.Remove('sToPort')
            $PollBody.vzEntry.attributes.Remove('dFromPort')
            $PollBody.vzEntry.attributes.Remove('dToPort')

        }elseif($EtherType -iin $('ip','ipv4','ipv6') -and $IPProtocol -iin 'tcp','udp'){
            if($IPProtocol -eq 'udp'){
                $PollBody.vzEntry.attributes.Remove('tcpRules')
                $PollBody.vzEntry.attributes.Remove('stateful')
            }

            if($PollBody.vzEntry.attributes.tcpRules -eq ''){
                $PollBody.vzEntry.attributes.Remove('tcpRules')

            }

            $PollBody.vzEntry.attributes.Remove('arpOpc')
            #IF Fragment enabled, then clear out the Ports
            if(!$MatchFragmentsOnly){
                $PollBody.vzEntry.attributes.Remove('applyToFrag')
            }else{
                
                $SourceFromPort = 0
                $SourceToPort = 0
                $DestinationFromPort = 0
                $DestinationToPort = 0
            }

            if($SourceFromPort -eq 0){
                $PollBody.vzEntry.attributes.Remove('sFromPort')
            }
            if(!$Stateful){
                $PollBody.vzEntry.attributes.Remove('stateful')
            }
            if($SourceToPort -eq 0){
                $PollBody.vzEntry.attributes.Remove('sToPort')
            }
            if($DestinationFromPort -eq 0){
                $PollBody.vzEntry.attributes.Remove('dFromPort')
            }
            if($DestinationToPort -eq 0){
                $PollBody.vzEntry.attributes.Remove('dToPort')
            }
        
        }


        #return $PollBody

    $JSONBody = $PollBody | ConvertTo-Json -Compress
    Set-Clipboard $JSONBody

    Write-Verbose "[New-ACISecurityContractFilterEntry] JSON:  `r`n$($JSONBody)"
    $Response = Start-ACICommand -Method POST -Url $PollURL -Encoding 'application/json' -PostData $JSONBody
    
    if($Response.httpcode -ge 200 -and $Response.httpcode -lt 300 ){
        return [PSCustomObject]@{
            status = 'success'
            dn = $PollBody.vzFilter.attributes.dn
            response = $Response
        }
    }else{
        return [PSCustomObject]@{
            status = 'failed'
            dn = $PollBody.vzFilter.attributes.dn
            response = $Response
        }
    }
}
    

# .ExternalHelp ACI-PoSH-help.xml
function New-ACITenant  {
    [cmdletbinding()] 
    param (
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=1)]
        $Tenant, 

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$False,Position=2)]
        $Description
    )
   
    #Define URL to pool
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json" -f $global:ACIPoSHAPIC, $Tenant

    $PollBody = @"
            {
                "fvTenant": {
                    "attributes": {
                        "dn": "uni/tn-$Tenant",
                        "name": "$Tenant",
                        "descr": "$Description",
                        "rn": "$Tenant",
                        "status": "created,modified"
                    },
                    "children": []
                }
            }
"@
$PollBody | Convertfrom-json | Convertto-json -Compress
    
    Try {
        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop
        #If not success, output the Raw Data and throw error
        if (!($PollRaw.httpCode -eq 200)) {
            $PollRaw.httpCode
            $PollRaw
            Write-Error -ErrorAction Stop -Category MetadataError  -Message  'An error occured after calling the API.  Function failed.' -ErrorAction Stop
        }
        else {
            Get-ACITenant | Where-Object { $_.Name -like $Tenant }
        }                 
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
}


# .ExternalHelp ACI-PoSH-help.xml
function New-ACIVRF {
    [cmdletbinding()] 
    param (
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=1)]
        $Tenant, 

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=2)]
        $VRF, 

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=3)]
        $Description
    ) 
    
    
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ctx-{2}.json" -f $global:ACIPoSHAPIC, $Tenant, $VRF
 
    $PollBody = @"
            {
                "fvCtx": {
                    "attributes": {
                        "dn": "uni/tn-$Tenant/ctx-$VRF",
                        "name": "$VRF",
                        "descr": "$Description",
                        "rn": "ctx-$VRF",
                        "status": "created"
                    },
                    "children": []
                }
            }
"@

    $PollBody | ConvertFrom-Json | ConvertTo-Json -Compress
    Try {
        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop
        #If not success, output the Raw Data and throw error
        if (!($PollRaw.httpCode -eq 200)) {
            $PollRaw.httpCode
            $PollRaw
            Write-Error -ErrorAction Stop -Category MetadataError  -Message  'An error occured after calling the API.  Function failed.' -ErrorAction Stop
        }
        else {
            Get-ACITenant | Where-Object { $_.Name -like $Tenant }
        }                 
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
}


# .ExternalHelp ACI-PoSH-help.xml
function New-ACIL3out {
    [cmdletbinding()] 
    param (
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=1)]
        $Tenant, 

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=2)]
        $VRF, 

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=3)]
        $L3out, 

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=4)]
        $Description
    ) 
   
    
    
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/out-{2}.json" -f $global:ACIPoSHAPIC, $Tenant, $L3out
 

    if(Get-ACIL3out -Tenant $Tenant -L3out $L3Out -ErrorAction SilentlyContinue){
        Return "L3Out Already Exists"
    }


    $PollBody = @"
                {
                    "l3extOut": {
                        "attributes": {
                            "dn": "uni/tn-$Tenant/out-$L3out",
                            "name": "$L3out",
                            "rn": "out-$L3out",
                            "status": "created"
                        },
                        "children": [{
                            "l3extRsEctx": {
                                "attributes": {
                                    "tnFvCtxName": "$VRF",
                                    "status": "created,modified"
                                },
                                "children": []
                            }
                        }]
                    }
                }   
"@

    #This doesn't compact normally and maintain the child, 
    #if you convert the json to a psobject and then back to 
    #json to compress it, it looses the children vrf node
     $PollBody = $PollBody -replace "\s+"," " -replace " ?\[ ?", "[" -replace " ?\] ?", "]" -replace " ?\{ ?", "{" -replace " ?\} ?", "}" -replace ", """, ","""

    Try {
        
        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop

        if (!($PollRaw.httpCode -eq 200)) {
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message 'An error occured after calling the API.  Function failed.'
            
        }
        else {
            Get-ACIL3out -Tenant $Tenant -L3out $L3out
        }           
    }
    Catch {
        Write-Error -ErrorAction Continue -Category InvalidArgument -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
}


# .ExternalHelp ACI-PoSH-help.xml
Function Remove-ACIBD {
    [cmdletbinding()] 
    param (
        [Parameter(Mandatory = $True,
            Position = 1)]
        [string]$Tenant,
        
        [Parameter(Mandatory = $True,
            Position = 2)]
        [string]$BD
    )

    if($Null -eq (Get-ACIBD -Tenant $TENANT -BD $BD ).Name){
        Write-Warning "[Remove-ACIBD]  BD '$BD' Does Not Exist in Tentant '$Tenant'"
        return $False
    }
    
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}.json" -f $global:ACIPoSHAPIC, $Tenant, $BD
        
    $PollBody = [ordered]@{
        fvBD = [ordered]@{
            attributes = @{
                dn = "uni/tn-$Tenant/BD-$BD"
                status             = "deleted"
            }
            children = [system.collections.arraylist]@()
        }
    }
    $PollRaw = Start-ACICommand -URL $PollURL -Method POST -PostData $($PollBody | ConvertTo-Json -Depth 10 -Compress)
    

    if (!($PollRaw.httpCode -eq 200)) {
        # Needs better output here but for now output
        $PollRaw.httpCode
        $PollRaw
        Write-Error -Category MetadataError -Message  'An error occured after calling the API.  Function failed.'
        
    }else{
        return $True
    }
}
#>

Function Remove-ACIBDSubnet {
    [cmdletbinding()] 
    param (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Tenant,
        
        [Parameter(Mandatory = $True, Position = 2)]
        [string]$BD,

        [ValidatePattern("^\d+\.\d+\.\d+\.\d+/\d+")]
        [Parameter(Mandatory = $True, Position = 3)]
        [string]$Subnet
    )

    
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}/subnet-[{3}].json?" -f $global:ACIPoSHAPIC, $Tenant, $BD, $Subnet
    $PollBody = @"
    {
        "fvSubnet": {
            "attributes": {
                "dn": "uni/tn-$Tenant/BD-$BD/subnet-[$Subnet]",
                "status": "deleted"
            },
            "children": []
        }
    }
"@
    $PollBody = $PollBody |ConvertFrom-Json | ConvertTo-Json -Depth 10 -Compress
    $PollRaw = Start-ACICommand -URL $PollURL -Method POST -PostData $PollBody
       
    if (!($PollRaw.httpCode -eq 200)) {
        # Needs better output here but for now output
        $PollRaw.httpCode
        $PollRaw
        Write-Error -ErrorAction Stop -Category MetadataError -Message  'An error occured after calling the API.  Function failed.'
    }else{
        return $True
    }

}


Function Add-ACIBDSubnet {
    [CmdletBinding(DefaultParameterSetName = 'Default',SupportsShouldProcess=$True)]
    param (
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]
        $Tenant,
        
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]
        $BD,

        [string]
        [ValidatePattern("^\d+\.\d+\.\d+\.\d+/\d+")]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]  
        $Subnet,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")]    
        $QuerierIP,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $NoDefaultSVIGateway,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $SharedBetweenVRF,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $VirtualIP,

        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $L3Out,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $AdvertisedExternally,
        
        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        $PrivateToVRF
    )


    
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}/subnet-[{3}].json" -f $global:ACIPoSHAPIC, $Tenant, $BD, $Subnet

    $SubnetSplit = $Subnet  -split "[.//\\]"
    if( $SubnetSplit[0] -notin 1..255 -or
        $SubnetSplit[1] -notin 1..255 -or
        $SubnetSplit[2] -notin 1..255 -or
        $SubnetSplit[3] -notin 1..255
    ){
        Write-Error -ErrorAction Stop -Message "$($SubnetSplit[0]).$($SubnetSplit[1]).$($SubnetSplit[2]).$($SubnetSplit[3]) Address is not Valid,  must be between 1.1.1.1 - 255.255.255.255"
    }elseif($SubnetSplit[4] -notin 0..32 ){
        Write-Error -ErrorAction Stop -Message "Subnet Bits is not Valid, must between 0-32"
    }
    Remove-Variable -Name SubnetSplit -ErrorAction SilentlyContinue


    if($VirtualIP){$Virtual='true'}else{$Virtual='false'}

    $Scope = @()
    if($SharedBetweenVRF){ $Scope += "shared" }
    if($PrivateToVRF  ){ $Scope += "private" }
    if($AdvertisedExternally  ){ $Scope += "public" }

    $Control = @()
    if($QuerierIP){ $Control += "querier" }
    if($NoDefaultSVIGateway  ){ $Control += "no-default-gateway" }
    


    $AttribSectn = @{
        dn ="uni/tn-$Tenant/BD-$BD/subnet-[$Subnet]"
        ctrl= "$($Control -join ",")"
        ip= "$Subnet"
        virtual= "$Virtual"
        scope= "$($Scope -join ",")"
        rn= "subnet-[$Subnet]"
        status= "created"
    }
    $PollBody = New-ACIJSONSection -SectionName "fvSubnet" -AttributesSection $AttribSectn

    if($Virtual -eq 'false'){
        $PollBody."fvSubnet".Attributes.remove("virtual")
    }

    if($L3Out -ne "" -or $Null -eq $L3Out){

    $AttribSectn=[Ordered]@{
        tnL3extOutName= "$L3Out"
        status= "created,modified"
    }
    $L3OutBody = New-ACIJSONSection -SectionName "fvRsBDSubnetToProfile" -AttributesSection $AttribSectn
    $PollBody.fvSubnet.Children.Add($L3OutBody)

    }else{$L3OutBody=""}



    $PollBodyJson = $PollBody | ConvertTo-Json -Compress
    write-verbose "[$($MyInvocation.MyCommand)] PollURL:  $PollURL"
    write-verbose "[$($MyInvocation.MyCommand)] PollBody:  $$PollBodyJson = $PollBody | ConvertTo-Json -Compress"

    if($PSCmdlet.ShouldProcess("$PollURL")){
        $PollRaw = Start-ACICommand -URL $PollURL -Method POST -PostData $PollBodyJson
    
        if (!($PollRaw.httpCode -eq 200)) {
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Write-Error -ErrorAction Stop -Category MetadataError -Message  'An error occured after calling the API.  Function failed.'
        }else{
            return $True
        }
    }

}

# .ExternalHelp ACI-PoSH-help.xml
# Create new Bridge Domain BD (L2)
function New-ACIBD  {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (

        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]
        $Tenant,
        
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]
        $VRF,
        
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]
        $BD,    
        
        [string]
        [Parameter(Mandatory = $false, ParameterSetName="Default")]
        [Parameter(Mandatory = $false, ParameterSetName="Private")]
        [Parameter(Mandatory = $false, ParameterSetName="Public")]
        $Alias,

        [string]
        [Parameter(Mandatory = $false, ParameterSetName="Default")]
        [Parameter(Mandatory = $false, ParameterSetName="Private")]
        [Parameter(Mandatory = $false, ParameterSetName="Public")]
        $Description,

        [switch]
        [Parameter(Mandatory = $false, ParameterSetName="Default")]
        [Parameter(Mandatory = $false, ParameterSetName="Private")]
        [Parameter(Mandatory = $false, ParameterSetName="Public")]
        $HostBasedRouting,

        [switch]
        [Parameter(Mandatory = $false, ParameterSetName="Default")]
        [Parameter(Mandatory = $false, ParameterSetName="Private")]
        [Parameter(Mandatory = $false, ParameterSetName="Public")]
        $Arpflooding,
        
        [string]
        [Parameter(Mandatory = $false, ParameterSetName="Default")]
        [Parameter(Mandatory = $false, ParameterSetName="Private")]
        [Parameter(Mandatory = $false, ParameterSetName="Public")]        
        [ValidatePattern("^(\d+[.]\d+[.]\d+[.]\d+[\\/]\d+|\s*)$")]
        $Subnet,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $NoIPLearning,

        [switch]
        [Parameter(Mandatory = $false, ParameterSetName="Default")]
        [Parameter(Mandatory = $false, ParameterSetName="Private")]
        [Parameter(Mandatory = $false, ParameterSetName="Public")]  
        $epMoveDetectMode,

        [switch]
        [Parameter(Mandatory = $false, ParameterSetName="Default")]
        [Parameter(Mandatory = $false, ParameterSetName="Private")]
        [Parameter(Mandatory = $false, ParameterSetName="Public")]  
        $NoUnicastRoute,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")]    
        $QuerierIP,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $NoDefaultSVIGateway,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $SharedBetweenVRF,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $VirtualIP,
        
        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        [ValidateScript(
            { $Policies = $(Get-ACITenantPolicyFirstHopBD -Tenant $Tenant -verbose:$False | SELECT-OBJECT  -ExpandProperty Name)
              if($Policies -contains $_ ){
                $True
              }else{
                Write-Warning "Valid FirstHop Policies: $($Policies -join ", ")"
                throw "`r`n## Matching FirstHop Policy ##" 
            }})]
        $FirstHopPolicy,

        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        [ValidateScript(
            { $Policies = $(Get-ACITenantPolicyMonitorAll -Tenant $Tenant -verbose:$False | SELECT-OBJECT  -ExpandProperty Name)
              if($Policies -contains $_ ){
                $True
              }else{
                Write-Warning "Valid Monitor Policies: $($Policies -join ", ")"
                throw "`r`n## No Matching Monitor Policy ##" 
            }})]
        $MonitorPolicy,
        
        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        [ValidateScript(
            {   $Policies = $(Get-ACITenantPolicyNeighborDiscovery -Tenant $Tenant -verbose:$False | SELECT-OBJECT  -ExpandProperty Name)
                if($Policies -contains $_ ){
                $True
            }else{
                Write-Warning "Valid Neighbor Discovery Policies: $($Policies -join ", ")"
                throw "`r`n## No Matching Neighbor Discovery ##" }})]
        $NeighborDiscoveryPolicy,

        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        
        [ValidateScript(
            {   $Policies = $( Get-ACIL3outAll  -Tenant $Tenant -verbose:$False | SELECT-OBJECT  -ExpandProperty Name)
                if($Policies -contains $_ ){
                $True
            }else{
                Write-Warning "Valid IGMP Policies: $($Policies -join ", ")"
                throw "`r`n## No Matching IGMP Policy ##" }
            }
            )]
        $L3Out,
        
        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        [ValidateScript(
            {   $Policies = $(Get-ACITenantPolicyIGMPSnooping -Tenant $Tenant -verbose:$False | SELECT-OBJECT  -ExpandProperty Name)
                if($Policies -contains $_ ){
                $True
            }else{
                Write-Warning "Valid IGMP Policies: $($Policies -join ", ")"
                throw "`r`n## IGMPPolicy Must not contain spaces or special characters. ##" }
            }
            )]
        $IGMPPolicy,
        
        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        [ValidateScript(
            {   $Policies = $(Get-ACITenantPolicyMonitorAll -Tenant $Tenant -verbose:$False | SELECT-OBJECT  -ExpandProperty Name)
                if($Policies -contains $_ ){
                $True
            }else{
                Write-Warning "Valid Endpoint Retention Policies: $($Policies -join ", ")"
                throw "`r`n## EndPointRetentionPolicy is not an existing Policy ##" }
            })]
        $EndPointRetentionPolicy,
        
        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        [ValidateScript(
            {   $Policies = $(Get-ACITenantPolicyMLDSSnoop -Tenant $Tenant -verbose:$False | SELECT-OBJECT  -ExpandProperty Name)
                if($Policies -contains $_ ){
                $True
            }else{
                Write-Warning "Valid MLDS Snooping Policies: $($Policies -join ", ")"
                throw "`r`n## MLDSSnoopPolicy Must not contain spaces or special characters. ##" }})]
        $MLDSSnoopPolicy,
        
        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        [ValidateScript(
        { $Policies = $(Get-ACITenantPolicyNetFlow -Tenant $Tenant -verbose:$False | SELECT-OBJECT  -ExpandProperty Name)
            if($Policies -contains $_ ){
                $True
            }else{
                Write-Warning "Valid NetflowPolicy Policies: $($Policies -join ", ")"
                throw "`r`n## NetflowPolicy Must not contain spaces or special characters. ##" 
        }})]
        $NetflowPolicy,
        
        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $AdvertisedExternally,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        $PrivateToVRF

    )
    
    if(@(Get-ACIBDall -Tenant NIPRNET  | Where-Object bd -eq $BD).count -gt 0){
        Write-Error "Bridge domain already Exists" -ErrorAction Stop
    }

    if($Subnet -match '^\s*$'){
        $Subnet = $Null
    }

    write-host 'x'
        
    $PollBody = [ordered]@{
        fvBD = [ordered]@{
            attributes = @{
                dn = "uni/tn-$Tenant/BD-$BD"
                mac                = "00:22:BD:F8:19:FF"
                name               = "$BD"
                nameAlias          = "$Alias"
                descr              = "$Description"
                rn                 = "BD-$BD"
                status             = "created"
            }

            children = [system.collections.arraylist]@(
                [ordered]@{
                    fvRsCtx = @{
                        attributes=@{
                            tnFvCtxName =$VRF
                            status = "created,modified"
                        }
                    }
                }
            )
        }
    }
 
    # Add HostBasedRouting if Supplied
    if($HostBasedRouting){
        $PollBody.fvBD.attributes.Add('hostBasedRouting', 'true')
    }

    # Add ARP Flooding if Supplied
    if($Arpflooding){
        
        $PollBody.fvBD.attributes.Add('arpFlood', 'true')
    }

    # Add EP Move Detection and set to gratuitous arp
    if($epMoveDetectMode){
        $PollBody.fvBD.attributes.Add('epMoveDetectMode', 'garp')
    }

    # Disable IP Learning
    if($NoIPLearning){
        $PollBody.fvBD.attributes.Add('ipLearning', 'false')
    }

    #Disable Unicast Routing
    if($NoUnicastRoute){
        $PollBody.fvBD.attributes.Add('unicastRoute', 'false')
    }

 
    # Apply the Netflow Child Object
    if ($NetflowPolicy -eq "") {
        Write-Verbose -Message  "No Netflow Policy specified"
    }else{
        
        [void] $PollBody.fvBD.children.Add(
            [PSCustomObject]@{
                fvRsBDToNetflowMonitorPol = @{
                    attributes=@{
                        tnNetflowMonitorPolName =$NetflowPolicy
                        status = "created"
                        fltType = "ipv4"
                    }
                }
            }
        )
        
    }

    # Apply the Endpoint Retention Policy Child Object
    if ($EndPointRetentionPolicy -eq "") {
        Write-Verbose -Message  "No Endpoint Retention Policy Specified"
    }else{
        
        [void] $PollBody.fvBD.children.Add(
            [ordered]@{
                fvRsBdToEpRet = @{
                    attributes=@{
                        tnFvEpRetPolName =$EndPointRetentionPolicy
                        status = "created,modified"
                    }
                }
            }
        )
    }
    
    # Apply the IGMP Policy Child Object
    if ("$IGMPPolicy" -eq "") {
        Write-Verbose -Message  "No IGMP Policy specified"
    }else{
        
        [void] $PollBody.fvBD.children.Add(
            [ordered]@{
                fvRsIgmpsn = @{
                    attributes=@{
                        tnIgmpSnoopPolName =$IGMPPolicy
                        status = "created,modified"
                    }
                }
            }
        )
    }

    
    # Apply the Endpoint Monitoring Policy Child Object
    if ("$MonitorPolicy" -eq "") {
        Write-Verbose -Message  "No IGMP Policy specified"
    }else{
        
        [void] $PollBody.fvBD.children.Add(
            [ordered]@{
                fvRsABDPolMonPol = @{
                    attributes=@{
                        tnMonEPGPolName =$MonitorPolicy
                        status = "created,modified"
                    }
                }
            }
        )
    }

    
    
    # Apply the FirstHop Security Policy Child Object
    if ("$FirstHopPolicy" -eq "") {
        Write-Verbose -Message  "No IGMP Policy specified"
    }else{
        
        [void] $PollBody.fvBD.children.Add(
            [ordered]@{
                fvRsBDToFhs = @{
                    attributes=@{
                        tnFhsBDPolName =$FirstHopPolicy
                        status = "created,modified"
                    }
                }
            }
        )
    }

    
    # Apply the MLDS Snooping Policy Child Object
    if ($MLDSSnoopPolicy -eq "") {
        Write-Verbose -Message  "No MLDS Snooping Policy"
    }else{
        
        [void] $PollBody.fvBD.children.Add(
            [ordered]@{
                fvRsMldsn = @{
                    attributes=@{
                        tnMldSnoopPolName =$MLDSSnoopPolicy
                        status = "created,modified"
                    }
                }
            }
        )
    }  

    
    # Apply the L3Out  Child Object
    if (!($L3out)) {
        Write-Verbose -Message  "No L3out specified"
    }else{
        
        [void] $PollBody.fvBD.children.Add(
            [ordered]@{
                fvRsBDToOut = @{
                    attributes=@{
                        tnL3extOutName =$L3out
                        status = "created"
                    }
                }
            }
        )
    }

    
    # Apply the Subnet Child Objects
    if("" -ne "$Subnet" ){
        $SubnetResult = Confirm-ValidSubnet -Subnet $Subnet -ErrorAction SilentlyContinue
        #$SubnetRegex = [regex]::match($Subnet,"^(?<oct1>\d+)[.](?<oct2>\d+)[.](?<oct3>\d+)[.](?<oct4>\d+)[\\/](?<netmask>\d+)$")   
        if($SubnetResult.Success){

            $Scope = @()
            if($SharedBetweenVRF){ $Scope += "shared" }
            if($PrivateToVRF  ){ $Scope += "private" }
            if($AdvertisedExternally  ){ $Scope += "public" }

            if($VirtualIP){$Virtual='true'}else{$Virtual='false'}

            $Control = @()
            if($QuerierIP){ $Control += "querier" }
            if($NoDefaultSVIGateway  ){ $Control += "no-default-gateway" }

                $SubnetSection = [ordered]@{
                    fvSubnet = @{
                        attributes=@{
                            dn = "uni/tn-$Tenant/BD-$BD/subnet-[$($SubnetResult.Subnet)]"
                            ctrl = "$($Control -join ",")"
                            ip   = $SubnetResult.Subnet
                            virtual = $Virtual
                            rn =  "subnet-[$($SubnetResult.Subnet)]"
                            status = "created"
                        }
                    }
                }
                if($Scope.count -gt 0){
                    $SubnetSection.fvSubnet.attributes.add('scope',$($Scope -join ","))
                }
            
                [void] $PollBody.fvBD.children.Add($SubnetSection)
                remove-variable -Name SubnetSection
            
        }else{
            Write-Verbose -Message  "No SVI specified"
        }
    }
    
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}.json" -f $global:ACIPoSHAPIC, $Tenant, $BD
 


    write-verbose "#################################"
    Write-Verbose "Poll URL: $PollURL"
    Write-Verbose ($PollBody  | ConvertTo-Json -Depth 10 | ConvertFrom-Json | ConvertTo-Json -Depth 10)
    $PollBodyJSON = $PollBody | ConvertTo-Json -Depth 10 -Compress

    Write-Verbose "JSON Compressed:`r`n$PollBodyJSON`r`n"


    Try {
        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBodyJSON -ErrorAction Stop
        if (!($PollRaw.httpCode -eq 200)) {
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Write-Error -ErrorAction Stop -Category MetadataError -Message  'An error occured after calling the API.  Function failed.'   
        }
        else {
            return Get-ACIBD -Tenant $Tenant -BD $BD
        }
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
}

Function Get-ACIBDReportEndpointsInBD{
    [cmdletbinding()]
    param(
        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        $Tenant, 

        [string]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [alias('bd-name')]
        $BD,

        [Int32]
        [Parameter()]
        $Limit=100


    )

    $Page = 0


    Write-Verbose "[Get-ACIBDReportEndpointsInBD] Limit: $Limit"
    Write-Verbose "[Get-ACIBDReportEndpointsInBD] Page: $Page"



    $ReturnObject = [System.Management.Automation.PSCustomObject[]]@()

    $PollURL = 'https://{0}/api/node/class/fvCEp.json?query-target-filter=eq(fvCEp.bdDn,"uni/tn-{1}/BD-{2}")&rsp-subtree=children&rsp-subtree-class=fvIp&order-by=fvCEp.mac|desc&page={3}&page-size={4}' -f $GLobal:ACIPoSHAPIC,$Tenant,$BD, $Page,$LIMIT
    $PollReponse = Start-ACICommand -Method GET -Url $PollURL 

    
    $TotalCount = ($PollReponse.httpResponse | ConvertFrom-json).totalCount
    Write-Verbose "[Get-ACIBDReportEndpointsInBD] TotalCount: $TotalCount"

    $ReturnObject += ($PollReponse.httpResponse | ConvertFrom-json).imdata.fvCEp.Attributes

    Return  @($ReturnObject)

}

# .ExternalHelp ACI-PoSH-help.xml
function New-ACIAppProfile  {
    [cmdletbinding()] 
    param  (
        [string]
        [Parameter(Mandatory = $True)]
        $Tenant, 

        [string]
        [Parameter(Mandatory = $True)]
        [alias('ap-name')]
        $AP, 

        [string]
        [Parameter(Mandatory = $False)]
        $Description,


        [string]
        [alias('ap-alias')]
        [Parameter(Mandatory = $False)]
        $Alias
    )

    #Generate Poll URL
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}.json" -f $global:ACIPoSHAPIC, $Tenant, $AP


    $PollBody = [Ordered]@{
            fvAp = [Ordered]@{
                attributes = [Ordered]@{
                    dn      = "uni/tn-$Tenant/ap-$AP"
                    name    = "$AP"
                    nameAlias   = $Alias
                    rn      =   "ap-$AP"
                    descr   = $Description
                    status  = "created"
                }
            }
    } | ConvertTo-Json -Compress 

    #Compress Post Data
    $PollBody = $PollBody | ConvertFrom-Json | ConvertTo-Json -Depth 10 -Compress
    
    Try {
        #Run Query
        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop

        if (!($PollRaw.httpCode -eq 200)) {
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message  'An error occured after calling the API.  Function failed.'
        }
        else {
            Get-ACIAppProfile -Tenant $Tenant -AP $AP
        }           
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
}


Function Remove-ACIEPG {
    [cmdletbinding()]
    param(
        [string]
        [parameter(mandatory)]
        [ValidatePattern("uni/tn-[^//]+/ap-[^//]+/epg-.*")]
        $DN
    )

    Remove-ACIObjectByDN -dn $DN -VariableName 'fvAEPg'

}

# .ExternalHelp ACI-PoSH-help.xml
function New-ACIEPG   {
    [cmdletbinding()] 
    param  (
        [string]
        [Parameter(Mandatory = $True)]
        $Tenant, 

        [string]
        [Parameter(Mandatory = $True)]
        [alias('ap-name')]
        $AP, 

        [string]
        [Parameter(Mandatory = $True)]
        $EPG, 

        [string]
        [Parameter(Mandatory = $True)]
        $BD, 

        [string]
        [Parameter(Mandatory = $False)]
        $Description, 

        [string]
        [Parameter(Mandatory = $False)]
        $Alias
    ) 


    if($Null -ne $Alias -and $Alias -ne ''){
        $Alias = """nameAlias"": ""$Alias"","
    }else{
        $Alias=""
    }
    
    #Generate Poll URL
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC, $Tenant, $AP, $EPG
    
    #Define Post Data
    $PollBody = @"
    {
        "fvAEPg": {
            "attributes": {
                "dn": "uni/tn-$Tenant/ap-$AP/epg-$EPG",
                "name": "$EPG",
                "rn": "epg-$EPG",
                "descr": "$Description",
                $Alias
                "status": "created"
            },
            "children": [{
                    "fvRsBd": {
                        "attributes": {
                            "tnFvBDName": "$BD",
                            "status": "created,modified"
                        },
                        "children": []
                    }
                }
            ]
        }
    }
"@

    #Compress Post Data
    $PollBody = $PollBody | ConvertFrom-Json | ConvertTo-Json -Depth 10 -Compress
    
    Try {
        #Execute Request
        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop

        if (!($PollRaw.httpCode -eq 200)) {   
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message 'An error occured after calling the API.  Function failed.'
    
        }
        else {
            Get-ACIEPG -Tenant $Tenant -AP $AP -EPG $EPG 
        }           
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
}


Function Remove-ACIEPGSubnet {
    [cmdletbinding(SupportsShouldProcess=$True)] 
    param (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Tenant,
        
        [Parameter(Mandatory = $True, Position = 2)]
        [alias('ap-name')]
        [string]$AP,

        [Parameter(Mandatory = $True, Position = 3)]
        [string]$EPG,

        [ValidatePattern("^\d+\.\d+\.\d+\.\d+/\d+")]
        [Parameter(Mandatory = $True, Position = 4)]
        [string]$Subnet
    )

    $PollURL    = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/subnet-[{4}].json" -f $global:ACIPoSHAPIC, $Tenant, $AP, $EPG, $Subnet
    $PollBody = @"
    {
        "fvSubnet": {
            "attributes": {
                "dn": "uni/tn-$Tenant/ap-$AP/epg-$EPG/subnet-[$Subnet]",
                "status": "deleted"
            },
            "children": []
        }
    }
"@
    $PollBody = $PollBody |ConvertFrom-Json | ConvertTo-Json -Depth 10 -Compress
    if($PSCmdlet.ShouldProcess("$PollURL")){
       $PollRaw = Start-ACICommand -URL $PollURL -Method POST -PostData $PollBody

        if (!($PollRaw.httpCode -eq 200)) {
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Write-Error -ErrorAction Stop -Category MetadataError -Message  'An error occured after calling the API.  Function failed.'
        }else{
            return $True
        }
    }

}


# .ExternalHelp ACI-PoSH-help.xml
function New-ACIInterfaceVPC {
    [cmdletbinding()] 
    param (

        [string]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## VPC policy name must not contain spaces or special characters. ##" }})]
        $VPCName,
        
        [string]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## LeafInterfaceProfile name must not contain spaces or special characters. ##" }})]
        $LeafInterfaceProfile,

        [string]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## AEP policy name must not contain spaces or special characters. ##" }})]
        $AEEP,
        
        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## LinkLevel policy must not contain spaces or special characters. ##" }})]
        $LinkLevel="",
        
        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## MacSec policy must not contain spaces or special characters. ##" }})]
        $MacSec="",

        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## LACP policy must not contain spaces or special characters. ##" }})]
        $LACP="",
        
        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## CooP policy must not contain spaces or special characters. ##" }})]
        $CooP="",
        
        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## CDP policy must not contain spaces or special characters. ##" }})]
        $CDP="",
        
        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## BPDU policy must not contain spaces or special characters. ##" }})]
        $BPDU="",
        
        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## L2Port policy must not contain spaces or special characters. ##" }})]
        $L2Port="",

        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## PortSecurity policy must not contain spaces or special characters. ##" }})]
        $PortSecurity="",
        
        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## LLDP policy must not contain spaces or special characters. ##" }})]
        $LLDP="",

        [int32]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -gt 0 -and $_ -le 90){
                $True
            }else{throw "`r`n## FromPort Must be between 1-90 ##" }})]
        $FromPort,
        
        [int32]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -gt 0 -and $_ -le 90){
                $True
            }else{throw "`r`n## ToPort Must be between 1-90 ##" }})]
        $ToPort,

        [string]
        [Parameter(Mandatory = $False)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## Switch name must not contain spaces or special characters. ##" }})]
        $SwitchName=""
    ) 
    
    
    #Phase 1 - Create the Fabric Interface Policy Group Poll URL
    $PollURL	= "https://{0}/api/node/mo/uni/infra/funcprof/accbundle-{1}.vpc.json" -f $global:ACIPoSHAPIC, $VPCName

    $Children= New-Object System.Collections.ArrayList

    if($LLDP -ne ""){
        Write-Verbose "LLDP Policy: $LLDP"
        [void] $Children.Add( @"
        {
            "infraRsLldpIfPol": {
                "attributes": {
                    "tnLldpIfPolName": "$LLDP",
                    "status": "created,modified"
                },
                "children": []
            }
        }
"@)
    }
    if($L2Port -ne ""){
        Write-Verbose "L2Port Policy: $L2Port"

        [void] $Children.Add( @"
        {
            "infraRsL2IfPol": {
                "attributes": {
                    "tnL2IfPolName": "$L2Port",
                    "status": "created,modified"
                },
                "children": []
            }
        }
"@)
    }
    if($PortSecurity -ne ""){
        Write-Verbose "PortSecurity Policy: $PortSecurity"
        [void] $Children.Add( @"
        {
            "infraRsL2PortSecurityPol": {
                "attributes": {
                    "tnL2PortSecurityPolName": "$PortSecurity",
                    "status": "created,modified"
                },
                "children": []
            }
        }
"@)
    }
    if($BPDU -ne ""){
        Write-Verbose "BPDU Policy: $BPDU"
        [void] $Children.Add( @"
        {
            "infraRsStpIfPol": {
                "attributes": {
                    "tnStpIfPolName": "$BPDU",
                    "status": "created,modified"
                },
                "children": []
            }
        }
"@)
    }
    if($CooP -ne ""){
        Write-Verbose "CooP Policy: $CooP"
        [void] $Children.Add( @"
        {
            "infraRsCoppIfPol": {
                "attributes": {
                    "tnCoppIfPolName": "$CooP",
                    "status": "created,modified"
                },
                "children": []
            }
        }

"@)
        
    }
    if($MacSec -ne ""){
        Write-Verbose "MacSec Policy: $MacSec"
        [void] $Children.Add( @"
        {
            "infraRsMacsecIfPol": {
                "attributes": {
                    "tnMacsecIfPolName": "$MacSec",
                    "status": "created,modified"
                },
                "children": []
            }
        }

"@)
        
    }
    if($CDP -ne ""){
        Write-Verbose "CDP Policy: $CDP"
        [void] $Children.Add( @"
        {
            "infraRsCdpIfPol": {
                "attributes": {
                    "tnCdpIfPolName": "$CDP",
                    "status": "created,modified"
                },
                "children": []
            }
        }

"@)
        
    }
    if($LACP -ne ""){
        Write-Verbose "LACP Policy: $LACP"
        [void] $Children.Add( @"
        {
            "infraRsLacpPol": {
                "attributes": {
                    "tnLacpLagPolName": "$LACP",
                    "status": "created,modified"
                },
                "children": []
            }
        }
"@)
    }
    if($LinkLevel -ne ""){
        Write-Verbose "LinkLevel Policy: $LinkLevel"
        [void] $Children.Add( @"
        {
            "infraRsHIfPol": {
                "attributes": {
                    "tnFabricHIfPolName": "$LinkLevel",
                    "status": "created,modified"
                },
                "children": []
            }
        }
"@)        
    }
    if($AEEP -ne ""){
        Write-Verbose "AEP Policy: $AEEP"
        [void] $Children.Add( @"
        {
            "infraRsAttEntP": {
                "attributes": {
                    "tDn": "uni/infra/attentp-$AEEP",
                    "status": "created,modified"
                },
                "children": []
            }
        }
"@)        
    }


    $PollBody= @"
    {
        "infraAccBndlGrp": {
            "attributes": {
                "dn": "uni/infra/funcprof/accbundle-$IntName",
                "lagT": "node",
                "name": "$IntName",
                "rn": "accbundle-$IntName",
                "status": "created"
            },
            "children": [
            ]
        }
    }
"@

    #Merge Children Objects into the parent and compress
    $PostData = $PollBody |  ConvertFrom-Json
    $PostData.infraAccBndlGrp.children = $Children | ConvertFrom-Json 
    $PollBody = $PostData | ConvertTo-Json -Depth 10 -Compress
    Remove-Variable -Name "PostData"

    Try {
        #Make API Call
        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $APIRawJson	= ($PollRaw.httpResponse	| ConvertFrom-Json).imdata
        
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
    
    # Phase 2 - Create the Fabric Interface Profile and Interface Selector
    $PollURL	= "https://{0}/api/node/mo/uni/infra/accportprof-{1}.json" -f $global:ACIPoSHAPIC, $LeafInterfaceProfile
    

    $PollBody = @"
    {
        "infraAccPortP": {
            "attributes": {
                "dn": "uni/infra/accportprof-$LeafInterfaceProfile",
                "name": "$LeafInterfaceProfile",
                "rn": "accportprof-$LeafInterfaceProfile",
                "status": "created,modified"
            },
            "children": [{
                    "infraHPortS": {
                        "attributes": {
                            "dn": "uni/infra/accportprof-$LeafInterfaceProfile/hports-$LeafInterfaceProfile-typ-range",
                            "name": "$LeafInterfaceProfile",
                            "rn": "hports-$LeafInterfaceProfile-typ-range",
                            "status": "created,modified"
                        },
                        "children": [{
                                "infraPortBlk": {
                                    "attributes": {
                                        "dn": "uni/infra/accportprof-$LeafInterfaceProfile/hports-$LeafInterfaceProfile-typ-range/portblk-block2",
                                        "fromPort": "$FromPort",
                                        "toPort": "$ToPort",
                                        "name": "block2",
                                        "rn": "portblk-block2",
                                        "status": "created, modified"
                                    },
                                    "children": []
                                }
                            }, {
                                "infraRsAccBaseGrp": {
                                    "attributes": {
                                        "tDn": "uni/infra/funcprof/accbundle-$VPCName",
                                        "status": "created,modified"
                                    },
                                    "children": []
                                }
                            }
                        ]
                    }
                }
            ]
        }
    }
"@

    #Merge Children Objects into the parent and compress
    $PostData = $PollBody |  ConvertFrom-Json
    $PostData.infraAccBndlGrp.children = $Children | ConvertFrom-Json 
    $PollBody = $PostData | ConvertTo-Json -Depth 10 -Compress
    Remove-Variable -Name "PostData"

    Try {
        #Make API Call
        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $FabricJSON	= ($PollRaw.httpResponse	| ConvertFrom-Json).imdata
        
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
    
    if($SwitchName -ne ""){
        #Phase 3 - Create the Switch Profile association
        #Define URL to pool
        $PollURL	= "https://{0}/api/node/mo/uni/infra/nprof-{1}.json" -f $global:ACIPoSHAPIC, $SwitchName
    
        $PollBody = @"
        {
            "infraRsAccPortP": {
                "attributes": {
                    "tDn": "uni/infra/accportprof-$LeafInterfaceProfile",
                    "status": "created,modified"
                },
                "children": []
            }
        }
"@

        Try {
            #Make API Call
            $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop
            #Poll the URL via HTTP then convert to PoSH objects from JSON
            $SwitchJSON	= ($PollRaw.httpResponse	| ConvertFrom-Json).imdata
        }
        Catch {	
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        }

        return [PSCustomObject]@{
            SwitchPolicy = $SwitchJSON
            FabricPolicy = $FabricJSON
            VPCPolicy = $APIRawJson
        }
    }
}

# .ExternalHelp ACI-PoSH-help.xml
function New-ACIInterface {
    [cmdletbinding()] 
    param (    
        [string]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## Switchname must not contain spaces or special characters. ##" }})]
        $SwitchName,

        [string]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## LeafInterfaceProfile name must not contain spaces or special characters. ##" }})]
        $LeafInterfaceProfile,
        
        [string]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
                $True
            }else{throw "`r`n## LeafAccessPolicy name must not contain spaces or special characters. ##" }})]
        $LeafAccessPolicy,    
        
        [int32]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -gt 0 -and $_ -le 90){
                $True
            }else{throw "`r`n## FromPort Must be between 1-90 ##" }})]
        $FromPort,
        
        [int32]
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { if($_ -gt 0 -and $_ -le 90){
                $True
            }else{throw "`r`n## ToPort Must be between 1-90 ##" }})]
        $ToPort
    )



    ##########################
    #Phase 1 - Create and define the profiles
    #Define URL to pool
    $PollURL	= "https://{0}/api/node/mo/uni/infra/accportprof-{1}/hports-{2}-typ-range.json" -f $global:ACIPoSHAPIC, $ProfileName, $LeafAccessPolicy
 
    $PollBody = @"
    {
        "infraHPortS": {
            "attributes": {
                "dn": "uni/infra/accportprof-$ProfileName/hports-$LeafAccessPolicy-typ-range",
                "name": "$LeafAccessPolicy",
                "rn": "hports-$LeafAccessPolicy-typ-range",
                "status": "created,modified"
            },
            "children": [{
                    "infraPortBlk": {
                        "attributes": {
                            "dn": "uni/infra/accportprof-$ProfileName/hports-$LeafAccessPolicy-typ-range/portblk-block2",
                            "fromPort": "$FromPort",
                            "toPort": "$ToPort",
                            "name": "block2",
                            "rn": "portblk-block2",
                            "status": "created,modified"
                        },
                        "children": []
                    }
                }, {
                    "infraRsAccBaseGrp": {
                        "attributes": {
                            "tDn": "uni/infra/funcprof/accportgrp-$LeafAccessPolicy",
                            "status": "created,modified"
                        },
                        "children": []
                    }
                }
            ]
        }
    }
"@    
    try {
        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop
    #Poll the URL via HTTP then convert to PoSH objects from, JSON
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        #Needs output validation here.  For now echo API return
        return $APIRawJson    
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }    
}

# .ExternalHelp ACI-PoSH-help.xml
function New-ACIAAALocalUser {
    [cmdletbinding()] 
    param (
        [string]
        [Parameter(Mandatory = $True)]
        $Username,

        [SecureString]
        [Parameter(Mandatory = $True)]
        $Password,

        [string]
        [Parameter(Mandatory = $True)]
        $SecDomain,

        [string]
        [Parameter(Mandatory = $True)]
        $SecRole,

        [string]
        [Parameter(Mandatory = $True)]
        $SecPriv,

        [string]
        [Parameter(Mandatory = $False)]
        $FirstName,

        [string]
        [Parameter(Mandatory = $False)]
        $LastName,

        [string]
        [Parameter(Mandatory = $False)]
        $email,

        [string]
        [Parameter(Mandatory = $False)]
        $phone,

        [string]
        [Parameter(Mandatory = $False)]
        $Description
    )
   

    $SecCred = New-Object system.management.automation.pscredential -ArgumentList $UserName, $Password

    #Define URL to pool
    $PollURL	= "https://{0}/api/node/mo/uni/userext/user-{1}.json" -f $global:ACIPoSHAPIC, $Username
 
    $PollBody = @"
    {
        "aaaUser": {
            "attributes": {
                "dn": "uni/userext/user-$Username",
                "name": "$Username",
                "rn": "user-$Username",
                "status": "created",
                "pwd": "$($SecCred.GetNetworkCredential().Password)"
            },
            "children": [{
                    "aaaUserDomain": {
                        "attributes": {
                            "dn": "uni/userext/user-$Username/userdomain-$SecDomain",
                            "name": "$SecDomain",
                            "status": "created,modified"
                        },
                        "children": [{
                                "aaaUserRole": {
                                    "attributes": {
                                        "dn": "uni/userext/user-$Username/userdomain-$SecDomain/role-$SecRole",
                                        "name": "$SecRole",
                                        "privType": "$SecPriv",
                                        "status": "created,modified"
                                    },
                                    "children": []
                                }
                            }
                        ]
                    }
                }
            ]
        }
    }
"@

    Try {
        Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop | Out-Null
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $VerificationURL = "https://{0}/api/node/mo/uni/userext/user-{1}.json" -f $global:ACIPoSHAPIC,$Username
        return ((Start-ACICommand -Method GET -url $VerificationURL).httpResponse | ConvertFrom-Json).imdata.aaaUser.Attributes
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
}



function Add-ACIEPGContract{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        $Tenant,
        
        [Parameter(Mandatory)]
        $AP,
        
        [Parameter(Mandatory)]
        $EPG,

        [Parameter(Mandatory)]
        $ContractName,

        [Parameter(Mandatory)]
        [ValidateSet('Provider','Taboo','Consumer')]
        $ContractType
    )

    switch($ContractType){
        'Provider' { $ContractMethod = 'fvRsProv' ; break }
        'Taboo'     { $ContractMethod = 'fvRsProtBy' ; break }
        'Consumer' { $ContractMethod = 'fvRsCons'; break }

    }

        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC, $Tenant, $AP, $EPG

        $DN = "uni/tn-{0}/ap-{1}/epg-{2}" -f $Tenant, $AP, $EPG 

        $PollBody = [Ordered]@{
            $ContractMethod = [Ordered] @{
                attributes = [Ordered] @{
                    tnVzBrCPName = $ContractName
                    status = "created,modified"
                }
                children=@()
            }
        }

        $PollBodyJson = $PollBody | ConvertTo-Json -Compress

        Write-Verbose "[Add-ACIEPGContract] PollURL: $PollURL"
        
        Write-Verbose "[Add-ACIEPGContract] PollBodyJson: $PollBodyJson"

        $PollRaw	= Start-ACICommand -Method POST -Url $PollURL -PostData $PollBodyJson -encoding "application/json"
            #Poll the URL via HTTP then convert to PoSH objects from JSON
        #$PollRaw.httpResponse	| ConvertFrom-Json | Write-Output

        if($PollRaw.httpCode -ge 200 -and $pollRaw.httpCode -lt 300){
            return [pscustomobject]@{
                httpcode = $PollRaw.httpCode
                dn       =  $DN
                ContractName = $ContractName
                success  = $True
            }
        }else{
            return [pscustomobject]@{
                httpcode = $PollRaw.httpCode
                dn       = $DN
                ContractName = $ContractName
                success  = $False
            }
        }
}


###################################################################################################################
## Update/Modify functions
###################################################################################################################

# .ExternalHelp ACI-PoSH-help.xml

function Update-ACIEPG {
    [Cmdletbinding(DefaultParameterSetName = "DefaultSet")]
    param (   
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="DefaultSet")]
        [Parameter(Mandatory = $false, ParameterSetName="Contract")]
        $Tenant,
        
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="DefaultSet")]
        [Parameter(Mandatory = $false, ParameterSetName="Contract")]
        [alias('ap-name')]
        $AP,
        
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="DefaultSet")]
        [Parameter(Mandatory = $false, ParameterSetName="Contract")]
        $EPG,
        
        [string]
        [Parameter(Mandatory = $false, ParameterSetName="DefaultSet")]
        [Parameter(Mandatory = $false, ParameterSetName="Contract")]
        $Domain,

        [string]
        [Parameter(Mandatory = $false,Position = 5, ParameterSetName="DefaultSet")]
        [Parameter(Mandatory = $false,Position = 5, ParameterSetName="Contract")]
        $BD,
        
        [string]
        [Parameter(Mandatory = $false,Position = 6, ParameterSetName="DefaultSet")]
        [Parameter(Mandatory = $false,Position = 8, ParameterSetName="Contract")]
        $Alias,
        
        [string]
        [Parameter(Mandatory = $true,Position = 6, ParameterSetName="Contract")]
        $Contract,
        
        [string]
        [Parameter(Mandatory = $true,Position = 7, ParameterSetName="Contract")]
        [ValidateSet("c","p", IgnoreCase=$False)]
        $ContractType
    )
   
    if ($Domain) {
        # Add domain binding
        
        #Define URL to pool
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC,$Tenant,$AP,$EPG

        $PollBody = @"
            {
                "fvRsDomAtt": {
                    "attributes": {
                        "resImedcy":"immediate",
                        "tDn":"uni/phys-$Domain",
                        "status":"created"
                    },
                    "children":[]
                }
            }
"@

        Try {
            $PollRaw    = Start-ACICommand -Method POST -URL $PollURL  -PostData $PollBody 
            #Poll the URL via HTTP then convert to PoSH objects from JSON
            $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
            #Needs output validation here.  For now echo API return
            Write-Output -InputObject $APIRawJson
            
        }
        Catch {
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        }
    }

    if ($Alias) {

        $PollBody = @"
            {
                "fvAEPg": {
                    "attributes": {
                        "dn": "uni/tn-$Tenant/ap-$AP/epg-$EPG",
                        "nameAlias": "$Alias"
                    },
                    "children": []
                }
            }
"@
            $PollBody = $PollBody -replace "\s+"," "
            Write-Verbose "PollBody: `r`n$PollBody"
        Try {

            $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC, $Tenant, $AP, $EPG
            Write-Verbose "PollURL: $PollURL"
            $PollRaw	= Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody
            
            $PollRaw.httpResponse	| ConvertFrom-Json | Write-Output 
    
            
        }
        Catch {
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        }

    }

    if ($Contract) {
        # Add contract to EPG
        # First check contract type etc
        if (!($ContractType)) {
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No contract type specified. Must be P/p (Provided) or C/c (Consumed)"
            
        }
        
        if ( (!($ContractType.ToLower()) -like 'c') -or (!($ContractType.ToLower()) -like 'p') ) {
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No contract type specified. Must be P/p (Provided) or C/c (Consumed)"
            
        }
        
        if ($ContractType -eq 'c') { $ContractMethod = 'fvRsCons' } 
        if ($ContractType -eq 'p') { $ContractMethod = 'fvRsProv' }
        
        #Add the contact, in the relevant direction/mode
        #Define URL to pool
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC, $Tenant, $AP, $EPG
        $PollBody = @"
        {
            "$ContractMethod": {
                "attributes": {
                    "tnVzBrCPName":"$Contract",
                    "status":"created,modified"
                },
                "children":[]
            }
        }
"@       

        Try {
            $PollRaw	= Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody
            #Poll the URL via HTTP then convert to PoSH objects from JSON
             $PollRaw.httpResponse	| ConvertFrom-Json | Write-Output
        }
        Catch {
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        }
    }

    if ($BD) {
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC, $Tenant, $AP, $EPG
        $PollBody = @"
            {
                "fvRsBd": {
                    "attributes": {
                        "tnFvBDName":"$BD",
                        "status":"created,modified"
                    },
                    "children":[]
                }
            }
"@
        Try {
            #Munge URL
            $PollRaw	= Start-ACICommand -Method POST -Url https://$global:ACIPoSHAPIC/$PollURL -PostData $PollBody
            #Poll the URL via HTTP then convert to PoSH objects from JSON
            $PollRaw.httpResponse	| ConvertFrom-Json | Write-Output
        }
        Catch {
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        }

    }
}

function Add-ACIEPGSubnet {
    [alias("Update-ACIEPGSubnet")]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]
        $Tenant,
        
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]
        [alias('ap-name')]
        $AP,
        
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]
        $EPG,
        
        [string]
        [Parameter(Mandatory = $True, ParameterSetName="Default")]
        [Parameter(Mandatory = $True, ParameterSetName="Private")]
        [Parameter(Mandatory = $True, ParameterSetName="Public")]        
        [ValidatePattern("^\d+[.]\d+[.]\d+[.]\d+[\\/]\d+$")]
        $Subnet,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")]    
        $QuerierIP,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $NoDefaultSVIGateway,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $SharedBetweenVRF,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $VirtualIP,

        [string]
        [Parameter(Mandatory = $False, ParameterSetName="Default")]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $L3Out,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Public")] 
        $AdvertisedExternally,

        [switch]
        [Parameter(Mandatory = $False, ParameterSetName="Private")]
        $PrivateToVRF

    )
    Begin{

        $SubnetSplit = $Subnet  -split "[.//\\]"
        if( $SubnetSplit[0] -notin 1..255 -or
            $SubnetSplit[1] -notin 1..255 -or
            $SubnetSplit[2] -notin 1..255 -or
            $SubnetSplit[3] -notin 1..255
        ){
            Write-Error -ErrorAction Stop -Message "$($SubnetSplit[0]).$($SubnetSplit[1]).$($SubnetSplit[2]).$($SubnetSplit[3]) Address is not Valid,  must be between 1.1.1.1 - 255.255.255.255"
        }elseif($SubnetSplit[4] -notin 0..32 ){
            Write-Error -ErrorAction Stop -Message "Subnet Bits is not Valid, must between 0-32"
        }

        $Subnet = "{0}.{1}.{2}.{3}/{4}" -f $SubnetSplit[0],$SubnetSplit[1],$SubnetSplit[2],$SubnetSplit[3],$SubnetSplit[4]
        Write-Verbose "Reformatted Subnet: $Subnet"

        $SubnetUrl    = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/subnet-[{4}].json" -f $global:ACIPoSHAPIC, $Tenant, $AP, $EPG, $Subnet
        Write-Verbose "Subnet Post URL: `r`n $SubnetUrl "
        
        if($L3Out){
            $SubnetL3OUrl = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/subnet-[{4}]/rsBDSubnetToProfile.json" -f $global:ACIPoSHAPIC, $Tenant, $AP, $EPG, $Subnet
            Write-Verbose "Subnet L3Out Post URL: `r`n $SubnetL3OUrl"
        }

        
        $Scope = @()
        if($SharedBetweenVRF){ $Scope += "shared" }
        if($PrivateToVRF  ){ $Scope += "private" }
        if($AdvertisedExternally  ){ $Scope += "public" }

        if($VirtualIP){$Virtual='true'}else{$Virtual='false'}

        $Control = @()
        if($QuerierIP){ $Control += "querier" }
        if($NoDefaultSVIGateway  ){ $Control += "no-default-gateway" }

    }
    Process{

        $PollBody = @"
            {
                "fvSubnet": {
                    "attributes": {
                        "dn": "uni/tn-$Tenant/ap-$AP/epg-$EPG/subnet-[$Subnet]",
                        "ctrl": "$($Control -join ",")",
                        "ip": "$Subnet",
                        "virtual": "$Virtual",
                        "scope": "$($Scope -join ",")",
                        "rn": "subnet-[$Subnet]",
                        "status": "created,modified"
                    },
                    "children": []
                }
            }
"@              
        $PollBody= $PollBody | ConvertFrom-Json | ConvertTo-Json -Compress
        Write-Verbose "PollBody: `r`n$PollBody"
        

        Try {
            $PollRaw  = Start-ACICommand -Method POST -Url $SubnetUrl -PostData $PollBody
   
            $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
            if($pollRaw.httpCode -eq 200){
                Write-Verbose "Success"
            }else{
                Write-Verbose "Failure: `r`nError Code: $($pollRaw.httpCode)`r`n$APIRawJson"
            }
        }
        Catch {
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        }

        if($L3Out){
            $PollBodyL3O = @"
            {
                "fvRsBDSubnetToProfile": {
                    "attributes": {
                        "tnL3extOutName": "L3O-$L3Out",
                        "status": "created,modified"
                    },
                    "children": []
                }
            }            
"@              
            $PollBodyL3O= $PollBodyL3O | ConvertFrom-Json | ConvertTo-Json -Compress
            Write-Verbose "PollBody L3Out: `r`n$PollBodyL3O"
            
            Try {               
                $PollRawL3O	= Start-ACICommand -Method POST -URL $SubnetL3OUrl -PostData $PollBodyL3O
                $APIRawJsonL3O	= $PollRawL3O.httpResponse	| ConvertFrom-Json
                if($PollRawL3O.httpCode -eq 200){
                    Write-Verbose "Success"
                }else{
                    Write-Verbose "Failure: `r`nError Code: $($PollRawL3O.httpCode)`r`n$APIRawJsonL3O"
                }
            }
            Catch {
                Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
            }

            return @($APIRawJson,$APIRawJsonL3O)
        }
    }

}

# .ExternalHelp ACI-PoSH-help.xml
function Update-ACIEPGPortBinding {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]
        [Parameter( Mandatory=$True)]
        $Tenant, 

        [string]
        [Parameter( Mandatory=$True)]
        [alias('ap-name')]
        $AP, 

        [string]
        [Parameter( Mandatory=$True)]
        $EPG, 

        [string]
        [Parameter( Mandatory=$True)]
        $VLAN, 

        [string]
        [ValidateSet('untagged','802.1p','vpc')]
        [Parameter( Mandatory=$True)]
        $PortType, 

        [string]
        [ValidatePattern("^([0-9]+|[0-9]+[-][0-9-]+)$")]
        [Parameter( Mandatory=$True)]
        $SwitchName, 

        [string]
        [alias("VPCName")]
        #[ValidatePattern("^([0-9]+/[0-9]+|[0-9]+/[0-9]+[-][0-9-]+)$")]
        [Parameter( Mandatory=$True)]
        $PortName,

        
        [string]
        [ValidatePattern("^(\d+)$")]
        [Parameter( Mandatory=$false)]
        $Pod="1",

        [switch]
        [Parameter( Mandatory=$false)]
        $Immediacy
 
    )
   
    
    #Just in case, munge the port type
    $PortType = $PortType.ToLower()
    
    #Define URL to pool
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC, $Tenant, $AP, $EPG
    

    if($Immediacy){
        $ImmediacyValue='"instrImedcy": "immediate",'
    }else{
        $ImmediacyValue=''
    }

    switch ($PortType){
        'untagged'{
            $Mode = """mode"": ""untagged"",`r`n"
            $TN = "topology/pod-{0}/paths-{1}/pathep-[eth{2}]" -f $Pod, $SwitchName, $PortName
            break
        }
        
        '802.1p '{
            $Mode = """mode"": ""native"",`r`n"
            $TN = "topology/pod-{0}/paths-{1}/pathep-[eth{2}]" -f $Pod, $SwitchName, $PortName
            break
        }

        'vpc'{
            $Mode = ""
            $TN = "topology/pod-{0}/protpaths-{1}/pathep-[{2}]" -f $Pod, $SwitchName , $PortName
            break
        }
        default{
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No correct port type."
        }
    }
    $PollBody = @"
    {
        "fvRsPathAtt": {
            "attributes": {
                "encap": "vlan-$VLAN",
                $ImmediacyValue
                $Mode
                "tDn": "$TN",
                "status": "created"
            },
            "children": []
        }
    }
    
"@
    write-verbose $PollBody
    $PollBody= $PollBody | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 10

    if($PSCmdlet.ShouldProcess("$PollURL")){
        Try {	
            $PollRaw	= Start-ACICommand -Method POST -URL $PollURL -PostData $PollBody
            return $PollRaw.httpResponse	| ConvertFrom-Json
            #Needs output validation here.  For now echo API return
            Write-Host $APIRawJson
        }
        Catch {
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        }
    }
}



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIEpgBD {    
    [CmdletBinding(DefaultParameterSetName = 'ALL')]
    param(
        [Parameter( Mandatory=$True, ParameterSetName="Tenant")]
        [Parameter( Mandatory=$True, ParameterSetName="AP")]
        [Parameter( Mandatory=$True, ParameterSetName="EPG")]
        [string]$Tenant,
        
        [Parameter( Mandatory=$True, ParameterSetName="AP")]
        [Parameter( Mandatory=$True, ParameterSetName="EPG")]
        [alias('ap-name')]
        [string]$AP,

        [Parameter( Mandatory=$True, ParameterSetName="EPG")]
        [string]$EPG

    )

    begin {

        $REGEX = [regex] "uni/tn-(?<tn>[^/]+)/ap-(?<ap>[^/]+)/epg-(?<epg>[^/]+)"
        $ReturnOutput = @()

        $PollURL = $Null   
        switch ($PSCmdlet.ParameterSetName ){
            "EPG"     {  $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json?query-target=subtree&target-subtree-class=fvRsBd"  -F $global:ACIPoSHAPIC, $Tenant , $AP, $EPG   }
            "AP"      {  $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}.json?query-target=subtree&target-subtree-class=fvRsBd" -F $global:ACIPoSHAPIC, $Tenant , $AP }
            "Tenant"  {  $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=subtree&target-subtree-class=fvRsBd" -F $global:ACIPoSHAPIC, $Tenant   }
            "ALL"     {  $PollURL = $Null }
            default   { Write-Error -Category InvalidOperation -ErrorAction Stop -Message "Some other Condition has been met, and will not continue." }
        }

    }        
    process {
        if($PollURL){
            $PollRaw = Start-ACICommand -Method GET -Url $PollURL
            # This object is wrapped in Array and converted to an array,
            # so it is corretly handled by the foreach loop later.
            $Results = @($PollRaw.httpResponse | ConvertFrom-Json)
            
            
        }else {
            $Results = foreach($Tenant in $(Get-ACITenant | Select-Object -ExpandProperty name)){
                $PollURL = "https://{0}/api/node/mo/uni/tn-{1}.json?query-target=subtree&target-subtree-class=fvAEPg&target-subtree-class=fvRsBd"  -F $global:ACIPoSHAPIC, $Tenant
                # This object is returned up the stack to $Results
                (Start-ACICommand -Method GET -Url $PollURL).httpResponse | ConvertFrom-Json 
            }
        }

        $ReturnOutput = foreach($Result in $Results){
            foreach($BD in $Result.imdata.fvRsBD.attributes){
                $Match = $REGEX.match($BD.dn)
                #This object is returned up the stack to $ReturnOutput
                [PSCustomObject]@{
                    epg = $Match.groups["epg"].value
                    epgdn = $Match.Groups[0].Value
                    ap = $Match.groups["ap"].value
                    tenant = $Match.groups["tn"].value
                    bd = $BD.tnFvBDName
                    bddn = $BD.tDn
                }     
            }
        }           
    }
    end {
        return $ReturnOutput
    }
}

function Add-ACIEPGPhysicalDomain {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [string][Parameter( ValueFromPipelineByPropertyName,Mandatory=$True)]
        $Tenant,
        
        [string][Parameter( ValueFromPipelineByPropertyName, Mandatory=$True)]
        [alias('ap-name')]
        $AP,
        
        [string][Parameter( ValueFromPipelineByPropertyName, Mandatory=$True)]
        $EPG,

        [string][Parameter( ValueFromPipelineByPropertyName, Mandatory=$True)]
        $Domain
    )
    
    Process{
        
        #Define URL to pool
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC,$Tenant,$AP,$EPG

        $PollBody = @"
            {
                "fvRsDomAtt": {
                    "attributes": {
                        "resImedcy":"immediate",
                        "tDn":"uni/phys-$Domain",
                        "status":"created"
                    },
                    "children":[]
                }
            }
"@
        $PollBody = $PollBody | ConvertFrom-Json | ConvertTo-Json -Depth 10 -Compress

        if($PSCmdlet.ShouldProcess("$PollURL")){
            Try {
                $PollRaw    = Start-ACICommand -Method POST -URL $PollURL  -PostData $PollBody 
                #Poll the URL via HTTP then convert to PoSH objects from JSON
                $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
                #Needs output validation here.  For now echo API return
                Write-Output -InputObject $APIRawJson
                
            }
            Catch {
                Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
            }
        }
    }
}


function Add-ACIEPGLayer2Domain {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [string][Parameter( ValueFromPipelineByPropertyName,Mandatory=$True)]
        $Tenant,
        
        [string][Parameter( ValueFromPipelineByPropertyName, Mandatory=$True)]
        [alias('ap-name')]
        $AP,
        
        [string][Parameter( ValueFromPipelineByPropertyName, Mandatory=$True)]
        $EPG,

        [string][Parameter( ValueFromPipelineByPropertyName, Mandatory=$True)]
        $Domain
    )
    
    Process{
        
        #Define URL to pool
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC,$Tenant,$AP,$EPG

        $PollBody = @"
            {
                "fvRsDomAtt": {
                    "attributes": {
                        "resImedcy":"immediate",
                        "tDn":"uni/l2dom-$Domain",
                        "status":"created"
                    },
                    "children":[]
                }
            }
"@
        $PollBody = $PollBody | ConvertFrom-Json | ConvertTo-Json -Depth 10 -Compress

        if($PSCmdlet.ShouldProcess("$PollURL")){
            Try {
                $PollRaw    = Start-ACICommand -Method POST -URL $PollURL  -PostData $PollBody 
                #Poll the URL via HTTP then convert to PoSH objects from JSON
                $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
                #Needs output validation here.  For now echo API return
                Write-Output -InputObject $APIRawJson
                
            }
            Catch {
                Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
            }
        }
    }
}

# .ExternalHelp ACI-PoSH-help.xml
function Add-ACIEPGVMMDomain {
    [cmdletbinding()]
    param(
        [string][Parameter( Mandatory=$True)]
        $Tenant,
        
        [string][Parameter( Mandatory=$True)]
        [alias('ap-name')]
        $AP,
        
        [string][Parameter( Mandatory=$True)]
        $EPG,

        [string][Parameter( Mandatory=$True)]
        $VMMDomain,

        [String][Parameter( Mandatory=$True)]
        [ValidateSet("True","False", IgnoreCase=$True)]
        $StaticVLAN,
        
        [Int32][Parameter( Mandatory=$False)]
        [alias("EndpointVLAN")]
        $VLAN,

        [Int32][Parameter( Mandatory=$False)]
        [alias("MicroSegmentVLAN")]
        $PrimaryVLAN,

        [string][Parameter( Mandatory=$False)]
        [ValidateSet("True","False", IgnoreCase=$True)]
        $MicroSegmentation="False",

        [string][Parameter( Mandatory=$False)]
        [ValidateSet("True","False","Yes","No", IgnoreCase=$True)]
        $Untagged="False",

        [string][Parameter( Mandatory=$False)]
        [ValidateSet("Dynamic","Ephemeral","Default","Static-Elastic","Static-Fixed", IgnoreCase=$True)]
        $PortBinding="Static-Elastic",

        [Int32][Parameter( Mandatory=$False)]
        $NumberOfPorts=10,

        [string][Parameter( Mandatory=$False)]
        [ValidateSet("Accept","Reject", IgnoreCase=$True)]
        $AllowPromiscuous="Reject",

        [string][Parameter( Mandatory=$False)]
        [ValidateSet("Accept","Reject", IgnoreCase=$True)]
        $ForgedTransmits="Reject",
        
        [string][Parameter( Mandatory=$False)]
        [ValidateSet("Accept","Reject", IgnoreCase=$True)]
        $MACChanges="Reject",

        [string][Parameter( Mandatory=$False, HelpMessage="Enter the Active Uplinks in the order you wish, sepereated by commas")]
        [ValidatePattern("^[\d ,]*$")]
        $ActiveUplinkOrder="",

        [string][Parameter( Mandatory=$False, HelpMessage="Enter the Standby Uplinks in the order you wish, sepereated by commas")]
        [ValidatePattern("^[\d ,]*$")]
        $StandbyUplinkOrder="",

        [string][Parameter( Mandatory=$False, HelpMessage="Enter the Standby Uplinks in the order you wish, sepereated by commas")]
        [ValidatePattern("^[A-Za-z 0-9\-_]*$")]
        $CustomEPGName="",
        
        [string][Parameter( Mandatory=$False, HelpMessage="Enter the Standby Uplinks in the order you wish, sepereated by commas")]
        [ValidateSet("","|","~","~","@","^","+","=","_")]
        $Delimiter="",

        [string][Parameter( Mandatory=$False)]
        [ValidateSet("Immediate","OnDemand")]
        $Deployment="OnDemand",
        
        [string][Parameter( Mandatory=$False)]
        [ValidateSet("Immediate","OnDemand","PreProvision")]
        $Resolution="PreProvision",
        
        [string][Parameter( Mandatory=$False)]
        [alias("LagPolicy")]
        $LagPolicyName=""
    )
    begin {

        if($StaticVLAN -ieq "True" -and $VLAN -lt 1 ){
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message "If Static Vlan is set to True, then a Value for VLAN Must be Supplied."
        }elseif($StaticVLAN -ieq "True" -and $MicroSegmentation -ieq "True" -and $PrimaryVLAN -lt 1){
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message "If Static Vlan & Microsegmentation are set to True, then a Value for PrimaryVLAN Must be Supplied."
        }

        if($StaticVLAN -ieq "True"){
            $Encap = "vlan-$VLAN"
        }else{
            $Encap = "unknown"
        }

        switch -Regex ($Untagged.ToLower()){
            "(true|yes)" { 
                $Untagged = "yes"
                break
            }
            "(false|no)" { 
                $Untagged = "no"
                break
            }
        }
        #Microsogmentation requres Immediate/Immediate, ignore user input for Resolution/Deployment
        #Set the Vlan Encapsulation String
        if($StaticVLAN -ieq "True" -and  $MicroSegmentation -ieq "True"){
            $PrimaryEncap = "vlan-$PrimaryVLAN"
        }else{
            $PrimaryEncap = "unknown"
        }

        if($MicroSegmentation -ieq "True"){
            $classPref="useg"
            $Resolution = "Immediate"
            $Deployment = "Immediate"
        }else{
            $classPref="encap"
        }
        
        $ActiveUplinkOrder =  $($ActiveUplinkOrder -replace " ","" -split "," | WHERE-OBJECT {$_ -ne ""} | Select-Object -Unique) -join ","
        $StandbyUplinkOrder =  $($StandbyUplinkOrder -replace " ","" -split "," | WHERE-OBJECT {$_ -ne ""} | Select-Object -Unique) -join ","

        $Uplinks = New-Object System.Collections.ArrayList
        
        if($ActiveUplinkOrder -ne ""){
            $Uplinks.Add( """active"":""$($ActiveUplinkOrder.Trim())""") | out-null
        }
        if($StandbyUplinkOrder -ne ""){
            $Uplinks.Add( """standby"":""$($StandbyUplinkOrder.Trim())""") | out-null
        }

        if($Uplinks.count -gt 0){
            
            $UplinkSection = @"
        , {"fvUplinkOrderCont": {"attributes": {$($Uplinks -join ",")"status":"created"},"children": []}}
"@  
        }else{
            $UplinkSection = ""
        }

        if($NumberOfPorts -eq 0){
            Write-Error -ErrorAction Stop -Category InvalidArgument -Message "NumberOfPorts must be configured to a value greater than 0"
        }
    
        switch($PortBinding){
            "Ephemeral"       { $BindingType = "elastic";        $portAllocation = "none"}
            "Dynamic"         { $BindingType = 'dynamicBinding'; $portAllocation = "none"}
            "Default"         { $BindingType = 'none';           $portAllocation = "none"} 
            "Static-Elastic"  { $BindingType = 'staticBinding';  $portAllocation = "elastic"}
            "Static-Fixed"    { $BindingType = 'staticBinding';  $portAllocation = "fixed"}
        }
        switch($Resolution){
            "Immediate"    {$resImedcy = "immediate"}
            "OnDemand"     {$resImedcy = "lazy"}
            "PreProvision" {$resImedcy = "pre-provision"}
        }
        switch($Deployment){
            "Immediate" {$instrImedcy = 'immediate'}
            "OnDemand"  {$instrImedcy = 'lazy'}
        }

        switch($StaticVLAN) {
            "true" {$EncapMode = "vlan"}
            "false" {$EncapMode = "auto"}
        }
    }
    process{
        $PollBody = @"
    {"fvRsDomAtt": {
        "attributes": {
            "resImedcy":"$resImedcy",
            "instrImedcy":"$instrImedcy",
            "numPorts":"$($NumberOfPorts.ToString())",
            "tDn":"uni/vmmp-VMware/dom-$VMMDomain",
            "portAllocation":"$portAllocation",
            "bindingType":"$BindingType",
            "delimiter":"$Delimiter",
            "encap":"$Encap",
            "primaryEncap":"$PrimaryEncap",
            "untagged":"$($Untagged.ToLower())",
            "classPref":"$classPref",
            "customEpgName": "$CustomEPGName",
            "encapMode": "$EncapMode",
            "status":"created,modified"
        },
        "children": [{
                "vmmSecP": {
                    "attributes": {
                        "allowPromiscuous":"$($AllowPromiscuous.ToLower())",
                        "forgedTransmits":"$($ForgedTransmits.ToLower())",
                        "macChanges":"$($MACChanges.ToLower())",
                        "status": "created,modified"
                    },
                    "children": []
                }
            }$UplinkSection
        ]
    }
} 
"@

        Try {
            #Munge URL
            $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $($global:ACIPoSHAPIC), $Tenant, $AP, $EPG
            $PollRaw	= Start-ACICommand -Method POST -Url $PollURL -postData $PollBody
            return $PollRaw.httpResponse	| ConvertFrom-Json
        }
        Catch {
            write-host $PollBody
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        }
    }

}
   

function Remove-ACIEPGVMMDomain {
        param(
            [string][Parameter( Mandatory=$True)]
            $Tenant,
            
            [string][Parameter( Mandatory=$True)]
            [alias('ap-name')]
            $AP,
            
            [string][Parameter( Mandatory=$True)]
            $EPG,
    
            [string][Parameter( Mandatory=$True)]
            $VMMDomain
        )
    begin{
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}.json" -f $global:ACIPoSHAPIC,$Tenant,$AP,$EPG
    }
    process{
        try{
            $PollBody=@"
            {
                "fvRsDomAtt": {
                    "attributes": {
                        "tDn": "uni/vmmp-VMware/dom-$VMMDomain",
                        "status": "deleted"
                    }
                }
            }
"@
            
            $Result = Start-ACICommand -Method POST -Url $PollURL -postData $PollBody
            return $Result.httpResponse	| ConvertFrom-Json
        }Catch{
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        }
    }
}


Function Remove-ACIEPGPath {
    [cmdletbinding(SupportsShouldProcess=$True)] 
    param  (
        [string]
        [Parameter(Mandatory = $True)]
        $Tenant, 

        [string]
        [Parameter(Mandatory = $True)]
        [alias('ap-name')]
        $AP, 

        [string]
        [Parameter(Mandatory = $True)]
        $EPG, 

        
        [Parameter(Mandatory = $True)]
        $Path

    )

    #Static Paths
    $PollUrl = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/rspathAtt-[{4}].json" -f $global:ACIPoSHAPIC, $Tenant, $Ap, $EPG, $Path
    try{
        $PollBody=@"
        {
            "fvRsPathAtt": {
                "attributes": {
                    "dn": "uni/tn-$TENANT/ap-$AP/epg-$EPG/rspathAtt-[$Path]",
                    "status": "deleted"
                },
                "children": []
            }
        }
"@

        Write-Verbose $PollUrl
        Write-Verbose $PollBody

        if($PSCmdlet.ShouldProcess("$PollURL")){
            $Result = Start-ACICommand -Method POST -Url $PollURL -postData $PollBody
            return $Result.httpResponse	| ConvertFrom-Json
        }
    }catch{
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
       
    }



}




function Remove-ACIEPGLayer2Domain {
    param(
        [string][Parameter( Mandatory=$True)]
        $Tenant,
        
        [string][Parameter( Mandatory=$True)]
        [alias('ap-name')]
        $AP,
        
        [string][Parameter( Mandatory=$True)]
        $EPG,

        [string][Parameter( Mandatory=$True)]
        $Domain
    )
    begin{
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/rsdomAtt-[uni/l2dom-{4}].json" -f $global:ACIPoSHAPIC,$Tenant,$AP,$EPG,$Domain
    }
    Process{
        try{
            $PollBody=@"
            {
                "fvRsDomAtt": {
                    "attributes": {
                        "dn": "uni/tn-$Tenant/ap-$AP/epg-$EPG/rsdomAtt-[uni/l2dom-$Domain]",
                        "status": "deleted"
                    },
                    "children": []
                }
            }
"@

            Write-Verbose $PollUrl
            Write-Verbose "`r`n$PollBody"

            $Result = Start-ACICommand -Method POST -Url $PollURL -postData $PollBody
            return $Result.httpResponse	| ConvertFrom-Json
        }catch{
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        
        }
    }
}

function Remove-ACIEPGPhysicalDomain {
    param(
        [string][Parameter( Mandatory=$True)]
        $Tenant,
        
        [string][Parameter( Mandatory=$True)]
        [alias('ap-name')]
        $AP,
        
        [string][Parameter( Mandatory=$True)]
        $EPG,

        [string][Parameter( Mandatory=$True)]
        $Domain
    )
    begin{
        $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}/epg-{3}/rsdomAtt-[uni/phys-PD-{4}].json" -f $global:ACIPoSHAPIC,$Tenant,$AP,$EPG,$Domain
    }
    Process{
        try{
            $PollBody=@"
            {
                "fvRsDomAtt": {
                    "attributes": {
                        "dn": "uni/tn-$Tenant/ap-$AP/epg-$EPG/rsdomAtt-[uni/phys-PD-$Domain]",
                        "status": "deleted"
                    },
                    "children": []
                }
            }
"@

            Write-Verbose $PollUrl
            Write-Verbose "`r`n$PollBody"

            $Result = Start-ACICommand -Method POST -Url $PollURL -postData $PollBody
            return $Result.httpResponse	| ConvertFrom-Json
        }catch{
            Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
        
        }
    }
}


function Get-ACIAdminExportPolicy {
    [cmdletbinding()]
    param ()

    $PollURL = "https://{0}/api/node/class/configExportP.json" -f $Global:ACIPoSHAPIC

    $PollResponse = Start-ACICommand -Method GET -Url $PollURL

    if($PollResponse.httpCode -lt 200 -and $PollResponse.httpcode -ge 300){
        Write-Error "HTTP Response Code: $($PollResponse.httpCode)" -ErrorAction Stop
    }else{
        return ($PollResponse.httpResponse | ConvertFrom-Json).imdata.configExportP.attributes
    }
}


function Add-ACIAdminSnapshot {
    [cmdletbinding(DefaultParameterSetName = 'Fabric')]
    param (
        [String]
        [Parameter()]
        $Description,
        [String]
        [Parameter()]
        $ExportPolicy = 'defaultOneTime',
        [switch]
        [Parameter()]
        $Wait,
        [switch]
        [Parameter(ParameterSetName = 'Fabric')]
        $Fabric,
        [string]
        [Parameter(ParameterSetName = 'Tenant',ValueFromPipelineByPropertyName)]
        $Tenant,
        [string]
        [Parameter()]
        $RemotePathName

    )
process{
    if($PSCmdlet.ParameterSetName -eq 'Fabric'){
        $Fabric = $true
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Generating Fabric Snapshot"
        $TargetDN = ''
        $Snapshot = 'true'

    }elseif($PSCmdlet.ParameterSetName -eq 'Tenant'){
        $Fabric = $False
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Generating Tenant Backup"
        $TargetDN = "uni/tn-$Tenant"
        $Snapshot = 'false'

    }else{
        Write-Error -ErrorAction Stop "Some other Condition was hit:  Current ParameterSet = $($PSCmdlet.ParameterSetName )"
    }



    $PollBody = [PSCustomObject]@{
        configExportP = [Ordered]@{
            attributes = [Ordered]@{
                dn      = "uni/fabric/configexp-$ExportPolicy"
                name    = $ExportPolicy
                snapshot = $Snapshot
                targetDn = $TargetDN
                adminSt = 'triggered'
                rn      = "configexp-$ExportPolicy"
                status  = "created,modified"
                descr   = "$Description"
            }
            children = @(
                [Ordered]@{
                    configRsRemotePath =[Ordered]@{
                        attributes = [Ordered]@{
                            tnFileRemotePathName = "$RemotePathName"
                            status =  "created,modified"
                        }
                        children=@()
                    }
                }
            )

        }
    }

    if("$RemotePathName" -eq ''){
        $PollBody.configExportP.remove('children')
        $PollBody.configExportP.attributes.snapshot = 'true'
    }else{
        $PollBody.configExportP.attributes.snapshot = 'false'
    }
    

    Write-Verbose "[$($MyInvocation.MyCommand.Name)] JSON:  $($PollBody | ConvertTo-Json -Depth 100)"
    

    $PollURL = "https://{0}/api/node/mo/uni/fabric/configexp-{1}.json" -f $global:ACIPoSHAPIC, $ExportPolicy

    
    Write-Verbose "[$($MyInvocation.MyCommand.Name)] PollURL:  $PollURL"

    $Result = Start-ACICommand -Method POST -Url $PollURL -PostData $($PollBody | ConvertTo-Json -Compress  -Depth 100)

    if($result.httpCode -ge 300 -or $Result.httpCode -lt 200){
        return   $Result.httpCode
    }


    if($Wait){
       $Job =  Get-ACIAdminSnapshotJobs -Size 1 -Page 0
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Name: $($Job.name)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Last State: $($Job.lastStepDescr)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Operation State: $($Job.operSt)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Details: $($Job.details)"

        
       while($Job.lastStepDescr.Trim() -ne 'Done'){
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Name: $($Job.name)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Last State: $($Job.lastStepDescr)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Operation State: $($Job.operSt)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Details: $($Job.details)"
         Start-Sleep -Milliseconds 300
         $Job =  Get-ACIAdminSnapshotJobs -Size 1 -Page 0
       }
       return [PSCustomObject]@{
            success = $true
            httpcode = $Result.httpCode
            job = $Job
        }
    }else{
       return [PSCustomObject]@{
            success = $true
            httpcode = $Result.httpCode
        }
    }

    }

}




function Get-ACIAdminSnapshotJobs {
    [cmdletbinding()]
    param (
        [Int32]
        [Parameter()]
        $Page=0,
        [Int32]
        [Parameter()]
        $Size = 1

    )

    $PollURL = "https://{0}/api/node/class/configJob.json?order-by=configJob.executeTime|desc&page={1}&page-size={2}" -f $global:ACIPoSHAPIC,$Page,$Size
    Write-Verbose "[$($MyInvocation.MyCommand.Name)] PollURL:  $PollURL"

    $Result = Start-ACICommand -Method GET -Url $PollURL 
    return ($Result.httpResponse | ConvertFrom-json).imdata.configJob.attributes
    

}

function Get-ACIAdminExportRemotePaths {
    [cmdletbinding()]
    param()

    $PollURL = "https://{0}/api/node/class/fileRemotePath.json" -f $global:ACIPoSHAPIC
    Write-Verbose "[$($MyInvocation.MyCommand.Name)] PollURL:  $PollURL"

    $Result = Start-ACICommand -Method GET -Url $PollURL 
    return ($Result.httpResponse | ConvertFrom-json).imdata.fileRemotePath.Attributes
    
}


function Get-ACIFabricSwitchFaultSummary{
    [cmdletbinding()]
    param(
        [Int32]
        [Parameter(Mandatory)]
        $SwitchNodeID,
        
        [Int32]
        [Parameter()]
        $PODID=1,
        [Int32]
        [Parameter()]
        $Page=0,
        [Int32]
        [Parameter()]
        $Size=15
    )

    $PollURL = 'https://{0}/api/node/class/topology/pod-{1}/node-{2}/faultSummary.json?query-target-filter=and()&order-by=faultSummary.severity|desc&page={3}&page-size={4}' -f $Global:ACIPoSHAPIC, $PODID, $SwitchNodeID,$Page,$Size

    Write-Verbose "[$($MyInvocation.MyCommand.Name)] PollURL:  $PollURL"

    $Response = Start-ACICommand -Method GET -Url $PollURL -Encoding 'application\json'
    return $($Response.httpResponse | ConvertFrom-Json).imdata.faultSummary.Attributes
}
