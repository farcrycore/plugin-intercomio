<cfcomponent displayname="Intercom" hint="Intercom API" extends="farcry.core.packages.forms.forms" output="false" key="intercom">
	
	<cfproperty name="prodAppID" type="string" default=""
				ftSeq="1" ftFieldSet="PRODUCTION API" ftLabel="PROD App ID" />

	<cfproperty name="prodSecretKey" type="string" default=""
				ftSeq="2" ftFieldSet="PRODUCTION API" ftLabel="PROD App Secret Key" />

	<cfproperty name="prodAccessToken" type="string" default=""
				ftSeq="3" ftFieldSet="PRODUCTION API" ftLabel="PROD App Access Token" />

	<cfproperty name="testAppID" type="string" default=""
				ftSeq="11" ftFieldSet="TEST API" ftLabel="TEST App ID" />

	<cfproperty name="testSecretKey" type="string" default=""
				ftSeq="12" ftFieldSet="TEST API" ftLabel="TEST App Secret Key" />

	<cfproperty name="testAccessToken" type="string" default=""
				ftSeq="13" ftFieldSet="TEST API" ftLabel="TEST App Access Token" />
	

	<cffunction name="buildRequestJSON" returntype="struct">
		<cfargument name="user" type="any" required="false" default="">
		<cfargument name="company" type="any" required="false" default="">

		<cfset var stAuthentication = structNew()>	
		<cfset var stUser = structNew()>	
		<cfset var stCompany = structNew()>	

		<cfset var stResult = structNew()>
		<cfset stResult.message = "">

		<!--- if data type is not query, convert convert to struct --->
		<cfif isQuery(arguments.user)>
			<cfset stUser = queryToStruct(arguments.user)>
		<cfelseif isStruct(arguments.user)>
			<cfset stUser = arguments.user>
		</cfif>

		<cfif isQuery(arguments.company)>
			<cfset stCompany = queryToStruct(arguments.company)>
		<cfelseif isStruct(arguments.company)>
			<cfset stCompany = arguments.company>
		</cfif>

		<cfif structKeyExists(stUser, "user_id") AND len(stUser.user_id)>
			<cfset stAuthentication = getAPIAuthentication(userID=stUser.user_id)>
		<cfelse>
			<cfset stAuthentication = getAPIAuthentication(userID="")>
		</cfif>

		<!--- append API ID & Key --->
		<cfset StructAppend(stUser, stAuthentication)>

		<!--- insert company metadata --->
		<cfif NOT structIsEmpty(stCompany)>
			<cfset StructInsert(stUser, "company", stCompany)>
		</cfif>

		<cfif validate(stUser)>
			<cfset stResult.stUser = stUser>
			<cfset stResult.bSuccess = true>
		<cfelse>	
			<cfset stResult.message = "Validation Failed, Please check required attributes">
			<cfset stResult.bSuccess = false>
		</cfif>

		<cfreturn stResult>

	</cffunction>

	<cffunction name="buildAPIUserJSON" returntype="struct">
		<cfargument name="user" type="any" required="false" default="">
		<cfargument name="company" type="any" required="false" default="">

		<cfset var stUser = structNew()>	
		<cfset var stCompany = structNew()>	
		<cfset var aCompanies = arrayNew(1)>
		<cfset var stResult = structNew()>
		<cfset stResult.message = "">

		<!--- if data type is not query, convert convert to struct --->
		<cfif isQuery(arguments.user)>
			<cfset stUser = queryToStruct(arguments.user)>
		<cfelseif isStruct(arguments.user)>
			<cfset stUser = arguments.user>
		</cfif>

		<cfif isQuery(arguments.company)>
			<cfset stCompany = queryToStruct(arguments.company)>
		<cfelseif isStruct(arguments.company)>
			<cfset stCompany = arguments.company>
		</cfif>

		<!--- insert company metadata --->
		<cfif NOT structIsEmpty(stCompany)>
			<cfset arrayAppend(aCompanies, stCompany) >
			<cfset StructInsert(stUser, "companies", aCompanies)>
		</cfif>

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

		<cfif StructCount(stMetadata) eq 1 AND structKeyExists(stMetadata,"app_id") AND len(stMetadata.app_id)> 
			<cfreturn true>
		</cfif>

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
			<cfif len(arguments.userID)>
				<cfset stResult["user_hash"] = getUserHash(arguments.userID, application.fapi.getConfig("intercom","prodSecretKey",""))>
			</cfif>
		<cfelse>
			<!--- test environment --->
			<cfset stResult["app_id"] = application.fapi.getConfig("intercom","testAppID","")>
			<cfif len(arguments.userID)>
				<cfset stResult["user_hash"] = getUserHash(arguments.userID, application.fapi.getConfig("intercom","testSecretKey",""))>
			</cfif>
		</cfif>

		<cfreturn stResult>
	</cffunction>

</cfcomponent>