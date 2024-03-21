# PowerShell for Cisco ACI (ACI-PoSH)

This is a set of PowerShell modules for Cisco ACI. These drive the native ACI RESTful API exposed by systems APIC's and expose these functions in PowerShell Commandlets.
> **NOTE:**
> You obviously need a PowerShell envionment that works.  This has been tested with Windows 10|11/Server 2012 R2|2016|2019 on Windows along with Cisco ACI Versions 4-5.x
> - Access to your Cisco ACI environment via HTTPS <b>and</b> credentials that have relevant access
> - You should be aware of commands you are running as well as the implications of doing so.
> - At present, MOST input is **not** filtered. If you make a typo, the API will execute it.
> - This set of modules is still under development. So please check back for more updates. There is a lot to do.
#### <i class="icon-file"></i> Installation
Copy the modules to either your PowerShell module directories (either for the system
or per user) <b>or</b>
Import the modules:
<pre>
Import-Module ACI-PoSH
</pre>
Your other alternative is to add these into a PowerShell script you run to start:
<pre>
#Import Functions
import-module

#Login (Optional)
 $Password = Read-Host -AsSecureString -Prompt Password
 New-AciLogin -Apic MyAPIC -Username MyUsername -Password  $Password
</pre>
#### <i class="icon-folder-open"></i> Authenticate to ACI
First step is to authenticate to the APIC.
<pre>> New-AciLogin -Apic MyAPIC -Username MyUsername -Password $Password</pre>
You should see the message <b>Authenticated!</b> 

If it fails, run the same command again. Occasionally the APIC API sometimes fails for no apparent reason.  Need to get to the bottom of this.
*	If you fail to supply a username then the currently logged in userlD (%username%) from Windows is used.
*	If you fail to supply a password, then you are prompted for it.
*	If you fail to supply a APIC name, then <b>APIC</b> is used as the hostname
  
>	**Tip:** ACI has very short session timers (300 seconds) and thus you will find you need to authenticate frequently.
#### <i class="icon-pencil"></i> Commands
Currently defined commands are:
<pre>
# I removed the list of commands here, as it was getting too long.   To find all of them run:

Get-Command -Noun ACI*

</pre>
All modules now have updated help text.   Hopefully that will be useful!
<pre>
Get-ACITenant

name        descr dn                
----        ----- --                
infra             uni/tn-infra      
common            uni/tn-common     
mgmt              uni/tn-mgmt       
companyA          uni/tn-companyA   
companyB    Co B  uni/tn-companyB   
companyC          uni/tn-companyC   
cloudMgmt         uni/tn-cloudMgmt  
secretAudit       uni/tn-secretAudit
</pre>	
As you see, we get useful paremeters shown along with the actual object (dn). The dn is not used by PoshACI but shown for completeness.
You can then run additional commands such as
<pre>get-ACIAppProfileAll -tenant ACI-TenX</pre>

**Tip:** - Remember ACI is case sensitive, including all configuration.
The above command will show all of the Application Profiles for Tenant TenX.

The **-All** identifier is used for some commandlets, rather than being the default for the commands. One to fix for later releases.

Now I have fixed the output/pipeline support remember how powerful PowerShell is so you can chain commands together.  For example: 

<pre>
Get-ACItenant | where-Object {$_.name -like '*Hos*'} | Get-ACIvrf | Where-Object {$_.name -notlike '*vrf*'} | Format-Table
</pre>

This searches for Tenants that have the string 'Hos' within, then gets their VRF's which don't have the string 'vrf' within.  Then outputs as a table !
