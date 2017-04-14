# Authentication and authorization with Identity Server 4

Few week ago I described how to build a custom Jwt authentication. Today I will show how we can use Identity server together with Resource owner password flow to authenticate and authorise your client to access your api.

This post will be composed by 3 parts:

1. Identity server configuration
2. Api protection
3. Client access

## 1. Identity server

Identity server is a framework which comes with Open ID Connect and OAuth 2.0 implementation.
The purpose of it is to decouple your api(s) from authentication and authorization logic. This has many advantages:

1. If you have multiple apis, you can hold your identities in a common place
2. If you have multiple apis, it provides you a way to have single sign on, meaning having a valid token for multiple apis
3. It provides a powerful way to configure client access to your api

There are many more advantages like the Open ID connect protocol implementation which handles consents and the handling of different authentication flows.

We will be looking at the Resource owner password flow.
It is the simplest flow but comes with two disavantages. 
1. Because it does not go through Open ID connect, we lose Single Sign On functionality as the user has to send username/password for each issuance of valid token.
2. We lose third party integration support from ID server as there is no redirect flow.

But if your application doesn't need those, then It would be the easiest flow to implement.

### 1.1 Configure the identity provider

The identity provider is a server responsible for holding all identities and providing access tokens which can be used to access protected resources.

There are few terms which have to be understood in order to configure the identity provider properly:

1. Api resources
2. Identity resources
3. Clients

What are resources?

Apis and Identities resources are resources that you wish to protect.

Api resources would be apis that you wish to protect, grant access to only certain clients.

Identity resources would be pieces of information from the identity itself that you wish to protect, like the address, the name or date of birth contained in the identity for example.

What the IDP (identity provider - the server delivering the identity) will provide is an access token which can be used to access either the Apis or the identity information. The identity information can be retrieved from the UserInfo endpoint on the IDP. We will see next that we can configure the middleware in the client to authomatically retrieve the identity claims by setting the property "GetAllUserClaims" to true.

Lastly, we can also define scopes within api resources which can be used to give granular access to clients. 
For example a client could be only allowed to list some data but not modify any data. We will see later how can a scope be validate for authorization on the api itself using policies.

In this example, we will have 3 pieces:
1. The identity provider
2. Our api we wish to protect
3. Our client - could be a website or an app or a client software, for this example I will use a client software

So let's start by configuring the identity provider. First we create an empty asp.net core project and add identityServer4 package.

Then from the Startup file we register the identity service and add the middleware.
Next we create a configuration file which will hold identity server configurations.

In order to have identity server working, we need to add api configurations, identity configurations, client configurations and some test users.

[code]

`AddTestUsers` adds a test provider and test users.
We can see from the Identity Server code what AddTestUser does:

[code]

We have GetApiResources and GetIdentityResources which we will be defining next.

## 2. Api resource

To protect the api,