<cfsetting enablecfoutputonly="true">
<!--- @@displayname: Intercom.io Integration --->

<cfif thistag.executionMode eq "Start">

<!---
window.intercomSettings {
	email: "bob@example.com",
	user_id: "123",
	app_id: "abc1234",
	created_at: 1234567890,
	"subdomain": "intercom", // Put quotes around text strings
	"teammates": 4, // Send numbers without quotes
	"active_accounts": 12,
	"last_order_at" : 1350466020, // Send dates in unix timestamp format and end key names with "_at"
	"custom_domain": null // Send null when no value exists for a user 

	"company" : { 
		"number_of_photos" : 1, // Increment a count up by 1
		"number_of_projects" : -1, // Increment a count down by 1
		"number_of_invoices" : 3 // Increment a count by a specified number
	}
}
--->

<!--- 
 // Required attributtes (case sensitive)

App
- 'app_id'
- 'app_key'

User
- 'id'
- or, 'user_id'
- or, 'email'

Company
- 'company_id'
-------------------------------------------------------------------------------->

<!--- 
 // tag attributes 
--------------------------------------------------------------------------------->
<cfparam name="attributes.user" default="">
<cfparam name="attributes.company" default="">



<!--- 
 // Build JSON request string for the create/update user API
--------------------------------------------------------------------------------->
<cfset oIntercom = createobject("component",application.stcoapi.configIntercom.packagePath) />
<cfset stResult = oIntercom.buildRequestJSON(user=attributes.user,company=attributes.company)>

<!--- 
 // render js embed
--------------------------------------------------------------------------------->
<cfoutput>
	<cfif stResult.bSuccess>
		<script>
		  window.intercomSettings = #serializejson(stResult.stUser)#;
		</script>

		<script>(function(){var w=window;var ic=w.Intercom;if(typeof ic==="function"){ic('reattach_activator');ic('update',intercomSettings);}else{var d=document;var i=function(){i.c(arguments)};i.q=[];i.c=function(args){i.q.push(args)};w.Intercom=i;function l(){var s=d.createElement('script');s.type='text/javascript';s.async=true;s.src='https://widget.intercom.io/widget/#stResult.stUser.app_id#';var x=d.getElementsByTagName('script')[0];x.parentNode.insertBefore(s,x);}if(w.attachEvent){w.attachEvent('onload',l);}else{w.addEventListener('load',l,false);}}})()</script>
	<cfelse>
		#stResult.message#
	</cfif>
</cfoutput>


</cfif>
<cfsetting enablecfoutputonly="false">