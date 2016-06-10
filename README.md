# Intercom Integration Plugin

References

* [Intercom Hompage](https://www.intercom.io/)
* [App Admin](https://app.intercom.io/ )
* [API Doc](https://developers.intercom.io/reference)

## Installation

You will require a Intercom App ID & API key for the application before you begin.

- unpack the plugin to `./farcry/plugins/intercom`
- register the plugin in the `./www/farcrycontructor.cfm`
- restart the application and deploy the Intercom config
- update the config with your Intercom APP ID & API key

## Implement in project
- 'user' and 'company(optional)' metadata can be either type of query or struct.
- Attributes are case-sensitive
- For 'user', At least one of following attributes are required ; `id`, `user_id` or `email`
- For 'company', it requires ; `company_id` 


## Example
```
<cfimport taglib="/farcry/plugins/intercom/tags/" prefix="tag" />

<cfset stUser = {  
		"app_id": "abc12345", 
		"email": "john.doe@example.com",
		"created_at": 1234567890,
		"name": "John Doe",
		"user_id": "9876",

		"company" : { 
			"company_id" : "123123123",
			"name" : "Daemon",
			"created_at: 1234567890,"
			"phone" : "98761234"}
}>

<cfset qCompany = getCompanyMetadata()>

<tag:intercom user="#stUser#" company="#qCompany#" />
```