<cfcomponent displayname="Intercom" hint="Intercom API" extends="farcry.core.packages.forms.forms" output="false" key="intercom">
	
	<cfproperty name="prodAppID" type="string" default=""
				ftSeq="1" ftFieldSet="PRODUCTION API" ftLabel="PROD App ID" />

	<cfproperty name="prodAppKey" type="string" default=""
				ftSeq="2" ftFieldSet="PRODUCTION API" ftLabel="PROD App Key" />

	<cfproperty name="testAppID" type="string" default=""
				ftSeq="11" ftFieldSet="TEST API" ftLabel="TEST App ID" />

	<cfproperty name="testAppKey" type="string" default=""
				ftSeq="12" ftFieldSet="TEST API" ftLabel="TEST App Key" />
	

	<cffunction name="buildRequestJSON" returntype="struct">
		<cfargument name="user" type="any" required="true">
		<cfargument name="company" type="any" required="false" default="">

		<cfset var stAuthentication = getAPIAuthentication(userID=user.user_id)>	
		<cfset var stUser = arguments.user>	
		<cfset var stCompany = arguments.company>	

		<cfset var stResult = structNew()>
		<cfset stResult.message = "">

		<!--- if data type is not query, convert convert to struct --->
		<cfif isQuery(arguments.user)>
			<cfset stUser = queryToStruct(arguments.user)>
		</cfif>

		<cfif isQuery(arguments.company)>
			<cfset stCompany = queryToStruct(arguments.company)>
		</cfif>

		<!--- append API ID & Key --->
		<cfset StructAppend(stUser, stAuthentication)>

		<!--- insert company metadata --->
		<cfset StructInsert(stUser, "company", stCompany)>

		<cfif validate(stUser)>
			<cfset stResult.stUser = stUser>
			<cfset stResult.bSuccess = true>
		<cfelse>	
			<cfset stResult.message = "Validation Failed, Please check required attributes">
			<cfset stResult.bSuccess = false>
		</cfif>

		<cfreturn stResult>

	</cffunction>

	<cffunction name="getUserHash" output="false">
		<cfargument name="user" type="string" required="true" />
		<cfargument name="secretkey" type="string" required="true" />

		<cfscript>
			var my_key = arguments.secretkey;
			var my_data = arguments.user;
			var digest = "";
			var secret = createObject('java', 'javax.crypto.spec.SecretKeySpec' ).Init(my_key.GetBytes(), 'HmacSHA256');
			var mac = createObject('java', "javax.crypto.Mac");
			mac = mac.getInstance("HmacSHA256");
			mac.init(secret);
			digest = mac.doFinal(my_data.GetBytes());
		</cfscript>

		<cfreturn BinaryEncode(digest, "Hex")>

	</cffunction>

	<cffunction name="queryToStruct" output="false" returntype="struct" hint="Convert query into struct. Keep column names case sensitive">
		<cfargument name="query" type="query" required="true" />

		<cfset var stResult = structNew()>
		<cfset var meta = getMetadata(arguments.query)>

		<cfloop array="#meta#" index="col">
			<cfset stResult[col.name] = arguments.query[col.name]>
		</cfloop>

		<cfreturn stResult>
	</cffunction>

	<cffunction name="validate" output="false" returntype="string" hint="validate metadata">
		<cfargument name="stMetadata" type="struct" required="true" />

		<!--- Required: id , user_id or email --->
		<cfif structKeyExists(stMetadata,"id") AND len(stMetadata.id)>
			<cfreturn true>
		
		<cfelseif structKeyExists(stMetadata,"user_id") AND len(stMetadata.user_id)>
			<cfreturn true>

		<cfelseif structKeyExists(stMetadata,"email") AND len(stMetadata.email)>
			<cfreturn true>
		</cfif>

		<!--- Required: company_id --->
		<cfif structKeyExists(stMetadata,"company") AND structKeyExists(stMetadata.company,"company_id") AND len(stMetadata.company.company_id)>
			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<cffunction name="getAPIAuthentication" output="false" returntype="struct" hint="Get API Id and key based on enviroment">
		<cfargument name="userID" type="string" required="true" />

		<cfset var stResult = structNew()>
		<cfset var env = application.fapi.getContentType(typename="configEnvironment").getEnvironment() />

		<cfif env eq "production">
			<!--- production environment --->
			<cfset stResult["app_id"] = application.fapi.getConfig("intercom","prodAppID","")>
			<cfset stResult["user_hash"] = getUserHash(arguments.userID, application.fapi.getConfig("intercom","prodAppKey",""))>
		<cfelse>
			<!--- test environment --->
			<cfset stResult["app_id"] = application.fapi.getConfig("intercom","testAppID","")>
			<cfset stResult["user_hash"] = getUserHash(arguments.userID, application.fapi.getConfig("intercom","testAppKey",""))>
		</cfif>

		<cfreturn stResult>
	</cffunction>

</cfcomponent>