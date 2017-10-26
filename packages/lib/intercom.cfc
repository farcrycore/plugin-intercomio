<cfcomponent displayname="Intercom API" hint="The API for all things intercom" output="false">


	<cffunction name="makeRequest" access="public" output="false" returntype="Struct">
		<cfargument name="resource" type="string" required="true" />
		<cfargument name="method" type="string" required="false" default="" />
		<cfargument name="stQuery" type="struct" required="false" default="#structnew()#" />
		<cfargument name="stData" type="struct" required="false" default="#structnew()#" />
		<cfargument name="format" type="string" required="false" default="json" />
		<cfargument name="timeout" type="numeric" required="false" default="30" />

		<cfset var accessToken = "" />
		<cfset var env = application.fapi.getContentType(typename="configEnvironment").getEnvironment() />
		<cfset var stResult = structnew() />
		<cfset var item = "" />
		<cfset var resourceURL = arguments.resource />

		<cfif env eq "production">
			<!--- production environment --->
			<cfset accessToken = application.fapi.getConfig("intercom","prodAccessToken","")>
		<cfelse>
			<!--- test environment --->
			<cfset accessToken = application.fapi.getConfig("intercom","testAccessToken","")>
		</cfif>

		<cfloop list="#structKeyList(arguments.stQuery)#" index="item">
			<cfif find("?", resourceURL)>
				<cfset resourceURL = resourceURL & "&" />
			<cfelse>
				<cfset resourceURL = resourceURL & "?" />
			</cfif>

			<cfset resourceURL = resourceURL & URLEncodedFormat(item) & "=" & URLEncodedFormat(arguments.stQuery[item]) />
		</cfloop>

		<cfif arguments.method eq "">
			<cfif structisempty(arguments.stData)>
				<cfset arguments.method = "GET" />
			<cfelse>
				<cfset arguments.method = "POST" />
			</cfif>
		</cfif>

		<cfhttp method="#arguments.method#" url="https://api.intercom.io#resourceURL#" timeout="#arguments.timeout#">
			<cfhttpparam type="header" name="Authorization" value="Bearer #accessToken#" />
			<cfhttpparam type="header" name="Accept" value="application/json"/>
			<cfif not structIsEmpty(arguments.stData)>
				<cfhttpparam type="header" name="Content-Type" value="application/json" />
				<cfhttpparam type="body" value="#serializeJSON(arguments.stData)#" />
			</cfif>
		</cfhttp>
		
		<cfif NOT structKeyExists(cfhttp, "statuscode")>
			<cfthrow message="Error accessing Intercom API" detail="Connection Failure: Status code unavailable." />
		<cfelseif not refindnocase("^20. ",cfhttp.statuscode)>
			<cfthrow message="Error accessing Intercom API: #cfhttp.statuscode#" detail="#serializeJSON({ 
				'resource' = arguments.resource,
				'method' = arguments.method,
				'query_string' = arguments.stQuery,
				'body' = arguments.stData,
				'resourceURL' = resourceURL,
				'response' = isjson(cfhttp.filecontent.toString()) ? deserializeJSON(cfhttp.filecontent.toString()) : cfhttp.filecontent.toString()
			})#" />
		</cfif>
		
		<cfset stResult.content = cfhttp.filecontent.toString() />

		<cfif len(stResult.content)>
			<cfswitch expression="#arguments.format#">
				<cfcase value="json">
					<cfset stResult.content = deserializeJSON(stResult.content) />
				</cfcase>
			</cfswitch>
		<cfelse>
			<cfset stResult.content = {} />
		</cfif>

		<cfif structKeyExists(cfhttp, "responseheader")>
			<cfset stResult.responseheader = cfhttp.responseheader />
		</cfif>

		<cfreturn stResult />
	</cffunction>

</cfcomponent>