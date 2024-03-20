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
        return $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvAp.attributes | Select-Object @{Label='AP';Expression={$_.name}}, descr, dn, @{Label='tenant';Expression={$Tenant}}
            
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
        $AP
    )
    # Define URL to pool
    $PollURL = "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}.json?query-target=subtree&target-subtree-class=fvAEPg" -f $global:ACIPoSHAPIC,$Tenant,$AP
   
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    
    return $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvAEPg.attributes | Select-Object name, prio, descr, dn
}

# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIEPG  {
	[cmdletbinding()]
    param(
        [string][Parameter( Mandatory=$True,ValueFromPipelineByPropertyName)]
        $Tenant,
        
        [string][Parameter( Mandatory=$True,ValueFromPipelineByPropertyName)]
        $AP,

        [string][Parameter( Mandatory=$True,ValueFromPipelineByPropertyName)]
        $EPG
    )
 
    
    if (!($Tenant)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Tenant specified"
    }
    if (!($Ap)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No Application Profile specified"
    }
    if (!($EPG)) {
        Write-Error -ErrorAction Stop -Category InvalidArgument -Message  "No EPG specified"
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

    $ReturnObject  = [PSCustomObject] @{
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
    }   

    return $ReturnObject
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
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$True,Position=2)]
        $AP
    ) 
    process {
        $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}.json?query-target=subtree&target-subtree-class=fvAEPg" -f $global:ACIPoSHAPIC, $Tenant, $Ap
        $PollRaw = Start-ACICommand -Method GET -Url $PollURL

        return $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvAEPg.attributes | Select-Object @{Label='epg';Expression={$_.name}},@{Label='ap';Expression={$AP}},@{Label='tenant';Expression={$Tenant}},@{Label='alias';Expression={$_.nameAlias}}, prio, descr, dn        
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

    return $($PollRaw.httpResponse | ConvertFrom-Json).imData.fvBd.attributes | Select-Object @{Label='bd';Expression={$_.name}}, descr, dn
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



# .ExternalHelp ACI-PoSH-help.xml
function Get-ACIFabricVLANPool  {
        [cmdletbinding()] 
    param (
        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=1)]
        $VLANPool,

        [string]
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true,Position=2)]
        [ValidateSet("static","dynamic", IgnoreCase=$true)]
        $AllocMode
    )
    
    # ACI stores VLAN pools as dynamic or static pools, and then saves the object differently
    $PollURL = "https://{0}/api/node/mo/uni/infra/vlanns-[{1}]-{2}.json?query-target=children&target-subtree-class=fvnsEncapBlk" -f $global:ACIPoSHAPIC, $VLANPool, $AllocMode.ToLower()
    $PollRaw = Start-ACICommand -Method GET -Url $PollURL
    return $($PollRaw.httpResponse | ConvertFrom-Json).imdata.fvnsEncapBlk.attributes 

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


###################################################################################################################
## Create functions
###################################################################################################################

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
    
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}.json?" -f $global:ACIPoSHAPIC, $Tenant, $BD

    $PollBody = @"
    {
        "fvBD": {
            "attributes": {
                "dn": "uni/tn-$Tenant/BD-$BD",
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
    

    if($L3Out -ne "" -or $Null -eq $L3Out){

        $L3OutBody = @"
    {
        "fvRsBDSubnetToProfile": {
            "attributes": {
                "tnL3extOutName": "$L3Out",
                "status": "created,modified"
            },
            "children": []
        }
    }
"@

    }else{$L3OutBody=""}

    $PollBody = @"
    {
        "fvSubnet": {
            "attributes": {
                "dn": "uni/tn-$Tenant/BD-$BD/subnet-[$Subnet]",
                "scope": "$($Scope -join ",")",
                "ctrl": "$($Control -join ",")",
                "ip": "$Subnet",
                "virtual": "$Virtual",
                "rn": "subnet-[$Subnet]",
                "status": "created"
            },
            "children": [$L3OutBody]
        }
    }
"@
    write-verbose "$PollBody"
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
    [ValidatePattern("^\d+[.]\d+[.]\d+[.]\d+[\\/]\d+$")]
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
        { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
            $True
        }else{throw "`r`n## L3Out Must not contain spaces or special characters. ##" }})]
    $L3Out,
    
    [string]
    [Parameter(Mandatory = $False, ParameterSetName="Default")]
    [Parameter(Mandatory = $False, ParameterSetName="Private")]
    [Parameter(Mandatory = $False, ParameterSetName="Public")] 
    [ValidateScript(
        { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
            $True
        }else{throw "`r`n## IGMPPolicy Must not contain spaces or special characters. ##" }})]
    $IGMPPolicy="",
    
    [string]
    [Parameter(Mandatory = $False, ParameterSetName="Default")]
    [Parameter(Mandatory = $False, ParameterSetName="Private")]
    [Parameter(Mandatory = $False, ParameterSetName="Public")] 
    [ValidateScript(
        { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
            $True
        }else{throw "`r`n## EndPointRetentionPolicy Must not contain spaces or special characters. ##" }})]
    $EndPointRetentionPolicy="",
    
    [string]
    [Parameter(Mandatory = $False, ParameterSetName="Default")]
    [Parameter(Mandatory = $False, ParameterSetName="Private")]
    [Parameter(Mandatory = $False, ParameterSetName="Public")] 
    [ValidateScript(
        { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
            $True
        }else{throw "`r`n## MLDSSnoopPolicy Must not contain spaces or special characters. ##" }})]
    $MLDSSnoopPolicy="",
    
    [string]
    [Parameter(Mandatory = $False, ParameterSetName="Default")]
    [Parameter(Mandatory = $False, ParameterSetName="Private")]
    [Parameter(Mandatory = $False, ParameterSetName="Public")] 
    [ValidateScript(
        { if($_ -notmatch "[ *!@#$%^&*()\[\]]"){
            $True
        }else{throw "`r`n## NetflowPolicy Must not contain spaces or special characters. ##" }})]
    $NetflowPolicy="",
    
    [switch]
    [Parameter(Mandatory = $False, ParameterSetName="Public")] 
    $AdvertisedExternally,

    [switch]
    [Parameter(Mandatory = $False, ParameterSetName="Private")]
    $PrivateToVRF

    )
    


    $Sections = New-Object System.Collections.ArrayList

    
        $Section= @"
            {
                "fvRsCtx": {
                    "attributes": {
                        "tnFvCtxName": "$VRF",
                        "status": "created,modified"
                    },
                    "children": []
                }
            }
"@       
    [void] $Sections.Add($Section)

    if ($NetflowPolicy -ne "") {
        Write-Verbose -Message  "No Netflow Policy specified"
    }else{
        $Section= @"
                    {
                        "fvRsBDToNetflowMonitorPol": {
                            "attributes": {
                                "tnNetflowMonitorPolName": "$NetflowPolicy",
                                "status": "created",
                                "fltType": "ipv4"
                            },
                            "children": []
                        }
                    }
"@                          
        [void] $Sections.Add($Section)
    
    }

    if ($EndPointRetentionPolicy -ne "") {
        Write-Verbose -Message  "No Endpoint Retention Policy Specified"
    }else{
        $Section= @"
                    {
                        "fvRsBdToEpRet": {
                            "attributes": {
                                "tnFvEpRetPolName": "$EndPointRetentionPolicy",
                                "status": "created,modified"
                            },
                            "children": []
                        }
                    }
"@                          
        [void] $Sections.Add($Section)
    
    }
    
    if ($IGMPPolicy -ne "") {
        Write-Verbose -Message  "No IGMP Policy specified"
    }else{
        $Section= @"
                {
                    "fvRsIgmpsn": {
                        "attributes": {
                            "tnIgmpSnoopPolName": "$IGMPPolicy",
                            "status": "created,modified"
                        },
                        "children": []
                    }
                }
"@                          
        [void] $Sections.Add($Section)
    
    }

    
    if ($MLDSSnoopPolicy -ne "") {
        Write-Verbose -Message  "No L3out specified"
    }else{
        $Section= @"
                {
                    "fvRsMldsn": {
                        "attributes": {
                            "tnMldSnoopPolName": "$MLDSSnoopPolicy",
                            "status": "created,modified"
                        },
                        "children": []
                    }
                }
"@                          
        [void] $Sections.Add($Section)
    
    }  


    if (!($L3out)) {
        Write-Verbose -Message  "No L3out specified"
    }else{
        $Section= @"
                    {
                    "fvRsBDToOut": {
                        "attributes": {
                            "tnL3extOutName": "$L3out",
                            "status": "created"
                        },
                        "children": []
                    }
                }
"@                          
        [void] $Sections.Add($Section)
    
    }

    if([regex]::match($Subnet,"^\d+[.]\d+[.]\d+[.]\d+[\\/]\d+$").Success){
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


        $Scope = @()
        if($SharedBetweenVRF){ $Scope += "shared" }
        if($PrivateToVRF  ){ $Scope += "private" }
        if($AdvertisedExternally  ){ $Scope += "public" }

        if($VirtualIP){$Virtual='true'}else{$Virtual='false'}

        $Control = @()
        if($QuerierIP){ $Control += "querier" }
        if($NoDefaultSVIGateway  ){ $Control += "no-default-gateway" }


        #Begin Building the Subnet Block.
        $Section= @"
            {
                "fvSubnet": {
                    "attributes": {
                        "dn": "uni/tn-$Tenant/BD-$BD/subnet-[$Subnet]",
                        "ctrl": "$($Control -join ",")",
                        "ip": "$Subnet",
                        "virtual": "$Virtual",
                        "scope": "$($Scope -join ",")",
                        "rn": "subnet-[$Subnet]",
                        "status": "created"
                    },
                    "children": []
                }
            }
"@
       [void] $Sections.Add($Section)
    }else{
        Write-Verbose -Message  "No SVI specified"
    }




    
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/BD-{2}.json" -f $global:ACIPoSHAPIC, $Tenant, $BD
 
    $PollBody = @"
    {
        "fvBD": {
            "attributes": {
                "dn": "uni/tn-$Tenant/BD-$BD",
                "epMoveDetectMode":"$( if($epMoveDetectMode){"garp"}else{""} )",
                "ipLearning": "$(if ($NoIPLearning){"false"})",
                "unicastRoute": "$(if ($NoUnicastRoute){"false"})",
                "mac": "00:22:BD:F8:19:FF",
                "arpFlood": "$( if($Arpflooding){"true"}else{""} )",
                "name": "$BD",
                "nameAlias": "$Alias",
                "descr": "$Description",
                "hostBasedRouting": "$( if($HostBasedRouting){"true"}else{""} )",
                "rn": "BD-$BD",
                "status": "created"
            },
            "children": []
        }
    }
"@



    $PostDataPSObj = $PollBody | ConvertFrom-Json 
    if($Sections.Count -gt 0){
        $PostDataPSObj.fvBD.Children = @($Sections | Convertfrom-json )
    }
    $PollBody = $PostDataPSObj | ConvertTo-Json -Depth 10 -Compress


    Try {

        $PollRaw = Start-ACICommand -Method POST -Url $PollURL -PostData $PollBody -ErrorAction Stop
        
        if (!($PollRaw.httpCode -eq 200)) {
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Write-Error -ErrorAction Stop -Category MetadataError -Message  'An error occured after calling the API.  Function failed.'
            
        }
        else {
            Get-ACIBD -Tenant $Tenant -BD $BD
        }
    }
    Catch {
        Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
    }
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
        $AP, 

        [string]
        [Parameter(Mandatory = $False)]
        $Description
    )

    #Generate Poll URL
    $PollURL	= "https://{0}/api/node/mo/uni/tn-{1}/ap-{2}.json" -f $global:ACIPoSHAPIC, $Tenant, $AP

    #Define Post Data
    $PollBody = @"
                {
                    "fvAp": {
                        "attributes": {
                            "dn": "uni/tn-$Tenant/ap-$AP",
                            "name": "$AP",
                            "rn": "ap-$AP",
                            "descr": "$Description",
                            "status": "created"
                        },
                        "children": []
                    }
                }
    
"@

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


# .ExternalHelp ACI-PoSH-help.xml
function New-ACIEPG   {
    [cmdletbinding()] 
    param  (
        [string]
        [Parameter(Mandatory = $True)]
        $Tenant, 

        [string]
        [Parameter(Mandatory = $True)]
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
                "pwd": "$SecCred.GetNetworkCredential().Password"
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
function New-ACIEPGVMMDomain {
    [cmdletbinding()]
    param(
        [string][Parameter( Mandatory=$True)]
        $Tenant,
        
        [string][Parameter( Mandatory=$True)]
        $AP,
        
        [string][Parameter( Mandatory=$True)]
        $EPG,

        [string][Parameter( Mandatory=$True)]
        $VMMDomain,

        [string][Parameter( Mandatory=$True)]
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
        [ValidatePattern("^[A-Za-z 0-9]*$")]
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

