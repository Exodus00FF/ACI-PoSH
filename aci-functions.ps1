switch($Null){
	$global:ACIPoSHCookieJar { $global:ACIPoSHCookieJar = New-Object System.Net.CookieContainer }
	$global:ACIPoSHAPIC { $global:ACIPoSHAPIC = '' }
    $global:ACIPoSHLoggedIn { $global:ACIPoSHLoggedIn  = $False }
	$global:ACIPoSHLoggingIn { $global:ACIPoSHLoggingIn = $False }

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

		
		Write-Verbose "Executing Start-ACICommand"
		Write-Verbose "Method: $Method"
		Write-Verbose "Encoding $Encoding"
		Write-Verbose "URL:  $URL"
		Write-Verbose "PostData: `r`n##########################`r`n$PostData`r`n##########################`r`n"
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
	if( $(split-path -leaf $url) -ine "aaaLogin.xml" -and (			
			[timespan]($(Get-Date) - $Global:TokenLastUpdate).Seconds -gt ($Global:TokenRefreshTimeoutSeconds - 10) -or  
			[timespan]($(Get-Date) - $Global:TokenStartTime).Seconds -gt ($Global:TokenmaximumLifetimeSeconds - 10) 
			)
		) 
	{
		Write-Verbose "Token has Expired reauthenticating"
		New-ACILogin -Password $Global:PW -Apic $Global:ACIPoSHAPIC
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
			$Global:TokenLastUpdate = Get-Date
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
	
# .ExternalHelp ACI-PoSH-help.xml
Function New-ACILogin
{
	[cmdletbinding()]
	param
	(
		[string]$Apic, 
		[String]$Username, 
		[SecureString]$Password,
		[String]$StoreLocation
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
	
	if (!($UserName)){
		## Assume no username specified so extract from Windows which should be the same credential
		$UserName = $env:USERNAME
	}
	if (!($StoreLocation)){
		## No credentail store location specified so check for password
		if (!($Password)){
			## No password specified thus prompt
			$Password = Read-Host -Prompt "No password or credential file was specified as an argument. Please enter your password " -AsSecureString
			## Clear screen just to remove from console view
			Clear-Host
		}
	}else{
		## Credential Stored file specified, so extract the password. This is not a straightforward operation !
		## Import the encrpted password and convert to a Secure String
		try{
			$Password = (ConvertTo-SecureString (Get-Content $StoreLocation))
		}catch{
			Write-Error -ErrorAction Stop -Category OpenError -Message  "Password file access failed. It may be missing. Please try again"
	
		}
	
 
	}

	try{
		$SecCred = New-Object system.management.automation.pscredential -ArgumentList $UserName,$Password
	}catch{
		Write-Error -ErrorAction Stop -Category AuthenticationError -Message  "Extraction of credential failed. Its contents are probably not valid. Please try again"
	}

	try{
		$null = $SecCred.GetNetworkCredential().Password
	}catch{
		Write-Error -ErrorAction Stop -Category InvalidData -Message   "Extraction of password failed. Please try again" 
	}

	## Set the logging in flag
	$global:ACIPoSHLoggingIn = $True;  $global:ACIPoSHLoggingIn | out-null
	## This is the URL we're going to be logging in to
	$loginurl = "https://" + $apic + "/api/aaaLogin.xml"
	## Format the XML body for a login
	$creds = '<aaaUser name="' + $UserName + '" pwd="' + $SecCred.GetNetworkCredential().Password + '"/>'
	## Execute the API Call
	$result = New-ACIApiCall -Method "POST" -Encoding "application/xml" -URL $loginUrl -Headers "" -PostData $creds
	remove-variable -Name creds
	if($result.httpResponse.Contains("Unauthorized")){
		Write-Error -ErrorAction Stop -Category AuthenticationError -Message  "Authentication to APIC failed! Please check your credentials."
	}else{
		[xml]$ResponseXML = $result.httpResponse
		$Global:TokenStartTime              = Get-date
		$Global:TokenLastUpdate             = Get-Date
		$Global:TokenRefreshTimeoutSeconds  = $ResponseXML.imdata.aaaLogin.refreshTimeoutSeconds
		$Global:TokenmaximumLifetimeSeconds = $ResponseXML.imdata.aaaLogin.maximumLifetimeSeconds
		$Global:TokenrestTimeoutSeconds = $ResponseXML.imdata.aaaLogin.restTimeoutSeconds

		switch($null){
			$Global:TokenStartTime { Write-Error -ErrorAction Stop -Message "Global:TokenStartTime was unable to be set"}
			$Global:TokenLastUpdate { Write-Error -ErrorAction Stop -Message "Global:TokenLastUpdate was unable to be set"}
			$Global:TokenRefreshTimeoutSeconds { Write-Error -ErrorAction Stop -Message "Global:TokenRefreshTimeoutSeconds was unable to be set"}
			$Global:TokenmaximumLifetimeSeconds { Write-Error -ErrorAction Stop -Message "Global:TokenmaximumLifetimeSeconds was unable to be set"}
			$Global:TokenrestTimeoutSeconds { Write-Error -ErrorAction Stop -Message "Global:TokenrestTimeoutSeconds was unable to be set" }
		}
		Write-Verbose "Authenticated!" 
	}
}