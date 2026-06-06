switch($Null){
	$global:ACIPoSHCookieJar { $global:ACIPoSHCookieJar = New-Object System.Net.CookieContainer }
	$global:ACIPoSHAPIC { $global:ACIPoSHAPIC = '' }
    $global:ACIPoSHLoggedIn { $global:ACIPoSHLoggedIn  = $False }
	$global:ACIPoSHLoggingIn { $global:ACIPoSHLoggingIn = $False }

}

Function New-ACIJSONSection {
	[cmdletbinding()]
	param(
		[string]
		[parameter(Mandatory)]
		$SectionName,

		[Hashtable]
		[Parameter(Mandatory)]
		$AttributesSection


	)

	$ReturnObject = @{
		"$SectionName" = [Ordered]@{
			attributes = [Ordered]@{
			}
			children=@()
		}

	}

	foreach($Attrb in $($AttributesSection.GetEnumerator()) ){
		$ReturnObject.$SectionName.attributes.Add("$($Attrb.Key)", $Attrb.Value)
	}
    return $ReturnObject

}


Function Start-ACICommand {
	[cmdletbinding()]
	param (
		[string]
		[Parameter(Mandatory = $True, Position = 1)] 
		[ValidateSet("GET","POST","PUT", IgnoreCase=$False)]
		$Method, 
		
		[string]
		[Parameter(Mandatory = $True, Position = 2)] 
		$Url, 

		[string]
		[Parameter(Mandatory = $false, Position = 3)] 
		$Encoding="", 

		[Parameter(Mandatory = $false, Position = 4)] 
		$Headers=@{}, 

		[string]
		[Parameter(Mandatory = $false, Position = 5)] 
		$PostData=""
		
	)
	
	Begin {
		$Method = $Method.ToUpper()

		
		Write-Verbose "[$($MyInvocation.MyCommand)]: Executing Start-ACICommand"
		Write-Verbose "[$($MyInvocation.MyCommand)]: Method: $Method"
		Write-Verbose "[$($MyInvocation.MyCommand)]: Encoding $Encoding"
		Write-Verbose "[$($MyInvocation.MyCommand)]: URL:  $URL"
		Write-Verbose "[$($MyInvocation.MyCommand)]: PostData: `r`n##########################`r`n$PostData`r`n##########################`r`n"
	}
	Process {
		Try {
			$PollRaw	= New-ACIApiCall -Method $Method -Encoding $Encoding -Url $Url  -PostData $PostData
			$APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
			if($PollRaw.httpCode -eq 200){
				Write-Verbose "Success"
			}elseif($ErrorActionPreference -eq [System.Management.Automation.ActionPreference]::SilentlyContinue ){
				#Do Nothing
			}else{
				Write-Error "Failure: `r`nError Code: $($PollRaw.httpCode)`r`n$APIRawJson" -ErrorAction Stop
			}
			return $PollRaw
		}
		Catch {
			if($ErrorActionPreference -eq [System.Management.Automation.ActionPreference]::SilentlyContinue ){
				#Do Nothing
			}else{
				Write-Error -ErrorAction Continue -Category MetadataError -Message "An error occured whilst calling the API. Exception: (`$_.Exception.Message)`r`n --- This is usually a typo or case issue, if you are sure you have the correct entries"
			}
			return $PollRaw
		}
	}
}

 
# .ExternalHelp ACI-PoSH-help.xml
Function New-ACIApiCall  {
	[cmdletbinding()]
	param (
		[string]
		[Parameter(Mandatory = $True, Position = 1)] 
		[ValidateSet("GET","POST","PUT", IgnoreCase=$False)]
		$Method, 
		
		[string]
		[Parameter(Mandatory = $True, Position = 2)] 
		$Url, 

		[string]
		[Parameter(Mandatory = $false, Position = 3)] 
		$Encoding, 
		
		[Parameter(Mandatory = $false, Position = 4)] 
		$Headers, 

		[string]
		[Parameter(Mandatory = $false, Position = 5)] 
		$PostData
	)

	$Method = $Method.ToUpper()

	#IF token is greater than Lastupdate Lifetime and MaxLifetime then Get a New Token
	if($(split-path -leaf $url) -inotin @("aaaLogin.xml","aaaRefresh.json")){
		if( $Global:ACITokenTimer.Elapsed.TotalSeconds -gt ($Global:ACITokenmaximumLifetimeSeconds - 10)){
			Write-Verbose "Token has hit Max Lifetime, ReAuthenticating"
			New-ACILogin -Password $Global:PW -Apic $Global:ACIPoSHAPIC
		}elseif( $Global:ACITokenRefreshTimer.Elapsed.TotalSeconds -gt ($Global:ACITokenRefreshTimeoutSeconds - 10)){
			Write-Verbose "Token at Timout Threshold, Refreshing Token"
			Update-ACIToken
		}
	}


	$return_value = New-Object PsObject -Property @{httpCode =""; httpResponse =""} 
		Try
		{
			## Create the request
			[System.Net.HttpWebRequest] $request = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($url)
			#
			# Ignore SSL certificate errors
			[System.Net.ServicePointManager]::ServerCertificateValidationCallback ={$true}
			#[System.Net.ServicePointManager]::SecurityProtocol = 3072 # <-- ACI NEEDS THIS

			# We want cookies!
			$request.CookieContainer = $global:ACIPoSHCookieJar
		}Catch{
            Write-Error -ErrorAction Stop -Category MetadataError -Message "An error occured whilst calling the API. Exception: $($_.Exception.Message)`r`n --- Please Try Again"
        
		}


		
		## Add the method (GET, POST, etc.)
		$request.Method = $method
		
		## Add an headers to the request
		ForEach($key in $headers.keys){
			$request.Headers.Add($key, $headers[$key])
		}
		
		## If we're logged in, add the saved cookies to this request
		If ($global:ACIPoSHLoggedIn -eq $True){
			$request.CookieContainer = $global:ACIPoSHCookieJar
			$global:ACIPoSHLoggingIn = $False
			
		}else{
			## We're not logged in to the APIC, start login first
			if($global:ACIPoSHLoggingIn -eq $False){
				$global:ACIPoSHLoggingIn = $True
				Write-Error -ErrorAction Stop -Category ConnectionError -Message "`r`nNot currently logged into APIC. Re-authenticate using the New-ACILogin commandlet "

			}
		}
		
		## We are using $encoding for the request as well as the expected response
		$request.Accept = $encoding
		## Send a custom user agent to ACI
		$request.UserAgent = "ACIPoSH Script"
			
		## Create the request body if the verb accepts it (NOTE: utf-8 is assumed here) 
		if ($method -eq "POST" -or $method -eq "PUT"){
			$bytes = [System.Text.Encoding]::UTF8.GetBytes($postData)
			$request.ContentType = $encoding
			$request.ContentLength = $bytes.Length
		
			try{
				[System.IO.Stream] $outputStream = 
				[System.IO.Stream]$request.GetRequestStream()
				$outputStream.Write($bytes,0,$bytes.Length) 
				$outputStream.Close()

			}catch{
				Write-Error -ErrorAction Stop  -Category ConnectionError -Message  "An error occured creating the stream connection. Please try again"
				
			}
		}
		
		##	This is where we actually make the call.
		try
			{
			[System.Net.HttpWebResponse] $response = [System.Net.HttpWebResponse] $request.GetResponse()

			foreach($cookie in $response.Cookies)
			{
				## We've found the APIC cookie and can conclude our login business
				if($cookie.Name -eq "APIC-cookie")
					{
					$global:ACIPoSHLoggedIn = $True 
					$global:ACIPoSHLoggingIn = $False
					}	
			}	
		
			$sr = New-Object System.IO.StreamReader($response.GetResponseStream())
			$txt = $sr.ReadToEnd()
			
			Write-Debug $("CONTENT-TYPE: {0}" -f $response.ContentType)
			Write-Debug $("RAW RESPONSE DATA:{0}" -f $txt)
			
			## Return the response body to the caller
			$return_value.httpResponse = $txt
			$return_value.httpCode = [int]$response.StatusCode
			return $return_value
		}

		## This catches errors from the server (404, 500, 501, etc.)
		catch [Net.WebException] {
			[System.Net.HttpWebResponse] $resp = [System.Net.HttpWebResponse] $_.Exception.Response
			Write-Debug $("Status Code: {0}" -f $resp.StatusCode)
			Write-Debug $("Status Desc: {0}" -f $resp.StatusDescription)
		## Return the error to the caller
		## If the APIC returns a 403, the session most likely has been expired. Login again and rerun the API call
		if($resp.StatusCode -eq 403){
			# We do this by resetting the global login variables and simply call the ACI-API-Call function again
			$global:ACIPoSHLoggedIn = $False
			$global:ACIPoSHLoggingIn = $False
			New-ACILogin -Password $Global:PW -Apic $Global:ACIPoSHAPIC
			New-ACIApiCall -Method $method -Encoding $encoding -URL $url -Headers $headers -PostData $postData
		}
		$return_value.httpResponse = $resp.StatusDescription
		$return_value.httpCode = [int]$resp.StatusCode
		return $return_value
		}
	}



Function Update-ACIToken {
	[cmdletbinding()]
	param(
	)

	Write-Verbose "[Update-ACIToken] Starting Token Refresh"
	$PollURL = "https://{0}/api/aaaRefresh.json" -f $global:ACIPoSHAPIC
	$Refresh =  New-ACIApiCall -Method GET -Encoding "application/json" -URL $PollURL 
	if($Refresh.httpCode -ge 200 -and $Refresh.httpCode -lt 300){
		Write-Verbose "ACI Token Timer Reset"
		$Global:ACITokenRefreshTimer.Restart()
	}
}
	
# .ExternalHelp ACI-PoSH-help.xml
Function New-ACILogin
{
	[cmdletbinding()]
	param
	(
		[string]$Apic, 
		[String]$Username, 
		[SecureString]$Password,
        [switch]$DoNotStoreCredentials
	 )

	##Check if an APIC was specified.
	if (!($Apic)){
		# No pipeline APIC specified so check for global varible
		If (!($global:ACIPoSHAPIC)){
			#No global APIC defined so prompt
			#$Apic = Read-Host -Prompt "No APIC was specified.	Please enter either hostname or IP address "
			Write-Host "No APIC specified. Trying APIC"
			$Apic = "apic02"
		}
	}else{
		$Global:ACIPoSHAPIC = $APIC
	}
	
	## Save the APIC name as a global var for the session
	$global:ACIPoSHAPIC = $apic
	
    
	if (!($UserName -and !$GLOBAL:ACISecCred)){
		## Assume no username specified so extract from Windows which should be the same credential
		$UserName = $env:USERNAME
	}else{
        $UserName = $GLOBAL:ACISecCred.Username
    }

	## No credentail store location specified so check for password
	if (!($Password) -and  !$GLOBAL:ACISecCred){
		## No password specified thus prompt
		$Password = Read-Host -Prompt "No password or credential file was specified as an argument. Please enter your password " -AsSecureString
		## Clear screen just to remove from console view
		Clear-Host
	}


    if($Null -eq $GLOBAL:ACISecCred){
	    try{
		    $GLOBAL:ACISecCred = New-Object system.management.automation.pscredential -ArgumentList $UserName,$Password
	    }catch{
		    Write-Error -ErrorAction Stop -Category AuthenticationError -Message  "Extraction of credential failed. Its contents are probably not valid. Please try again"
	    }
    }

	try{
		$null = $GLOBAL:ACISecCred.GetNetworkCredential().Password
	}catch{
		Write-Error -ErrorAction Stop -Category InvalidData -Message   "Extraction of password failed. Please try again" 
	}

	## Set the logging in flag
	$global:ACIPoSHLoggingIn = $True;  

	## This is the URL we're going to be logging in to
	$loginurl = "https://" + $apic + "/api/aaaLogin.xml"
    Write-Verbose "Login URL: $LoginURL"


	## Format the XML body for a login
	$creds = '<aaaUser name="' + $UserName + '" pwd="' + $GLOBAL:ACISecCred.GetNetworkCredential().Password + '"/>'
    Write-Verbose "Credential Obj: '<aaaUser name='$UserName' pwd='***************'/>"

	## Execute the API Call
	$result = New-ACIApiCall -Method "POST" -Encoding "application/xml" -URL $loginUrl -Headers "" -PostData $creds
	remove-variable -Name creds -ErrorAction SilentlyContinue
	Write-Verbose "API Call Result:  '$Result'"

	if($result.httpResponse.Contains("Unauthorized")){
        Remove-Variable -Scope Global -Name ACISecCred -ErrorAction SilentlyContinue
		Write-Error -ErrorAction Stop -Category AuthenticationError -Message  "Authentication to APIC failed! Please check your credentials."
	}else{
		[xml]$ResponseXML = $result.httpResponse
		$Global:ACITokenTimer                  = [diagnostics.stopwatch]::startnew()
		$Global:ACITokenRefreshTimer                  = [diagnostics.stopwatch]::startnew()
		Write-Verbose "Updated ACI Token Timer"
		$Global:ACITokenRefreshTimeoutSeconds  = $ResponseXML.imdata.aaaLogin.refreshTimeoutSeconds
		Write-Verbose "Token Refresh Timeout Seconds : $($Global:ACITokenRefreshTimeoutSeconds)"
		$Global:ACITokenmaximumLifetimeSeconds = $ResponseXML.imdata.aaaLogin.maximumLifetimeSeconds
		Write-Verbose "Token Max Lifetime Secs : $($Global:ACITokenmaximumLifetimeSeconds)"
		$Global:ACITokenrestTimeoutSeconds = $ResponseXML.imdata.aaaLogin.restTimeoutSeconds
		Write-Verbose "Token Rest Timeout Secs : $($Global:ACITokenrestTimeoutSeconds)"

		switch($null){
			<#
			$Global:ACITokenStartTime { Write-Error -ErrorAction Stop -Message "Global:TokenStartTime was unable to be set"}
			$Global:ACITokenLastUpdate { Write-Error -ErrorAction Stop -Message "Global:TokenLastUpdate was unable to be set"}#>
			$Global:ACITokenRefreshTimeoutSeconds { Write-Error -ErrorAction Stop -Message "Global:TokenRefreshTimeoutSeconds was unable to be set"}
			$Global:ACITokenmaximumLifetimeSeconds { Write-Error -ErrorAction Stop -Message "Global:TokenmaximumLifetimeSeconds was unable to be set"}
			$Global:ACITokenrestTimeoutSeconds { Write-Error -ErrorAction Stop -Message "Global:TokenrestTimeoutSeconds was unable to be set" }
		}
		Write-Verbose "Authenticated!" 
	}

    if($DoNotStoreCredentials){
        Remove-Variable -Scope GLOBAL -Name ACISecCred -ErrorAction SilentlyContinue
    }

}


function Confirm-ValidSubnet{
	[cmdletbinding()]
	param(
		[string]
		[Parameter(Mandatory = $True)]      
		$Subnet
	)
	
	$ReturnObject = [PSCustomObject]@{
		Success=$False
		IP=""
		Netmask=""
		Subnet=""
	}

	Write-Verbose "[Confirm-ValidSubnet] Provided Value = '$Subnet'"

	$SubnetRegex = [regex]::match($Subnet,"^(?<oct1>\d+)[.](?<oct2>\d+)[.](?<oct3>\d+)[.](?<oct4>\d+)[\\/]?(?<netmask>\d+)?$")   
    
	if($SubnetRegex.Success){
        if( $SubnetRegex.Groups['oct1'].value -notin 1..255 -or
            $SubnetRegex.Groups['oct2'].value -notin 1..255 -or
            $SubnetRegex.Groups['oct3'].value -notin 1..255 -or
            $SubnetRegex.Groups['oct4'].value -notin 1..255
        ){

            Write-Error -ErrorAction Stop -Message "$($SubnetRegex.Groups['oct1'].value).$($SubnetRegex.Groups['oct2'].value).$($SubnetRegex.Groups['oct3'].value).$($SubnetRegex.Groups['oct4'].value) Address is not Valid,  must be between 1.1.1.1 - 255.255.255.255"
        }elseif($SubnetRegex.Groups['netmask'].value -notin 1..32 ){
            Write-Error -ErrorAction Stop -Message "Subnet Bits are not Valid, must between 1-32"
        }else{
			$ReturnObject.Subnet = "{0}.{1}.{2}.{3}/{4}" -f $SubnetRegex.Groups['oct1'].value, $SubnetRegex.Groups['oct2'].value, $SubnetRegex.Groups['oct3'].value, $SubnetRegex.Groups['oct4'].value, $SubnetRegex.Groups['netmask'].value
			$ReturnObject.IP = "{0}.{1}.{2}.{3}" -f $SubnetRegex.Groups['oct1'].value, $SubnetRegex.Groups['oct2'].value, $SubnetRegex.Groups['oct3'].value, $SubnetRegex.Groups['oct4'].value
			$ReturnObject.Netmask = $SubnetRegex.Groups['netmask'].value
			$ReturnObject.Success = $True


		}
	}else{
		$ReturnObject.Success = $False
	}

	Write-Verbose "[Confirm-ValidSubnet] Returned Subnet  = '$($ReturnObject.Subnet)'"
	Write-Verbose "[Confirm-ValidSubnet] Returned IP      = '$($ReturnObject.IP)'"
	Write-Verbose "[Confirm-ValidSubnet] Returned Netmask = '$($ReturnObject.Netmask)'"
	Write-Verbose "[Confirm-ValidSubnet] Returned Success = '$($ReturnObject.Success)'"

	return $ReturnObject

}
