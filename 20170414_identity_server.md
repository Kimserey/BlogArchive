# Authentication and authorization with Identity Server 4

Few week ago I described how to build a [custom Jwt authentication](https://kimsereyblog.blogspot.sg/2017/01/authentication-for-websharper-sitelet.html). 
Today I will show how we can use [Identity server](http://docs.identityserver.io/en/release/) together with Resource owner password flow to authenticate and authorise your client to access your api.

This post will be composed by 3 parts:

```
1. Identity server
2. Protect an api
3. Configure a client
```

## 1. Identity server

Identity server is a framework which implements Open ID Connect and OAuth 2.0 protocols.
The purpose of Identity server is to centralize the identity management and at the same time decouple your api(s) from authentication and authorization logic.
Centralizing has many advantages:

- If you have multiple apis, you can hold your identities in a common place
- If you have multiple apis, it provides single sign on - user only sign in into one client and is automatically sign in in all apis. This works because all clients will redirect to the same authority which will be able to verify that the user is already logged in
- It provides a powerful way to configure client access to your api

There are many more advantages like the Open ID connect protocol implementation which handles consents and the handling of different authentication flows.
In this post, we will be looking at the `Resource owner password flow`. It is the simplest flow but comes with two disavantages:
- We lose Single Sign On as the user has to send username/password for each issuance of valid token
- We lose third party integration support from ID server as there is no redirect flow
But if your application doesn't need those, then It would be the easiest flow to implement.

### 1.1 Configure the identity provider

The identity provider is a server responsible for holding all identities and providing access tokens which can be used to access protected resources. The api/identity resources are the resources that you wish to protect.
Api resources would be apis that you wish to protect, grant access to only certain clients.
Identity resources would be pieces of information from the identity itself that you wish to protect, like the address, the name or date of birth contained in the identity for example.

What the identity provider will provide an access token which can be used to access either the Apis or the identity information. The identity information can be retrieved from the `UserInfo` endpoint on the identity provider. We will see next that we can configure the middleware in the client to authomatically retrieve the identity claims by setting the property `GetClaimsFromUserInfoEndpoint` to true.

In this example, we will have 3 pieces:
- The identity provider
- Our api we wish to protect
- Our client - could be a website or an app or a client software, for this example I will use a client software

So let's start by configuring the identity provider. First we create an empty asp.net core project and add identityServer4 package.

Then from the Startup file we register the identity service and add the middleware.

```
// -- This is in the Identity provider

public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        //... some other services here

        services.AddIdentityServer()
                .AddInMemoryApiResources(Configs.GetApiResources())
                .AddInMemoryClients(Configs.GetClients())
                .AddInMemoryIdentityResources(Configs.GetIdentityResources())
                .AddTestUsers(Configs.GetTestUsers())
                .AddTemporarySigningCredential();
    }

    public void Configure(IApplicationBuilder app, ILoggerFactory loggerFactory)
    {
        //... some code here

        app.UseIdentityServer();
    }
}
```

From the service registration, we can already see that we will need to give the configuration of our `Api resources`, `Clients`, `Identity resources` and some test users.

So next we can create a configuration file which will hold identity server configurations.

```
// -- This is in the Identity provider

public class Configs
{
    public static IEnumerable<IdentityResource> GetIdentityResources()
    {
        return new List<IdentityResource>();
    }

    public static IEnumerable<ApiResource> GetApiResources()
    {
        return new List<ApiResource>();
    }

    public static IEnumerable<Client> GetClients()
    {
        return new List<Client>();
    }

    public static List<TestUser> GetTestUsers()
    {
        return new List<TestUser> {
            new TestUser {
                SubjectId = "1",
                Username = "alice",
                Password = "password"
            }
        };
    }
}
```

Take note that `AddTestUsers` adds a `profile service` and a `resource owner password validator` which we would need to provide when not using test users. We can see from the Identity Server code what `AddTestUser` does:

```
// -- Code from Identity Server 4 source code

public static IIdentityServerBuilder AddTestUsers(this IIdentityServerBuilder builder, List<TestUser> users)
{
    builder.Services.AddSingleton(new TestUserStore(users));
    builder.AddProfileService<TestUserProfileService>(); //<--- we will need to implement this
    builder.AddResourceOwnerValidator<TestUserResourceOwnerPasswordValidator>(); <-- and this
    return builder;
}
```

Next we will protect our api.

## 2. Protect an API

Let's start a web api project and add `IdentityServer4.AccessTokenValidation`.
This library allows us to protect the api by using the `IdentityServerAuthentication` middleware which will validate the access tokens.

So we place the following code before our `MVC` middleware binding:
```
// -- This is in the API

public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory)
{
    // ... some other stuff

    app.UseIdentityServerAuthentication(new IdentityServerAuthenticationOptions
    {
        Authority = "http://localhost:5000",
        ApiName = "api",
        ApiSecret = "secret",
        AutomaticAuthenticate = true,
        RequireHttpsMetadata = false,
    });

    app.UseMvc();
}
```

In the option, we specify the `endpoint of the identity provider`, our `api name`, the `secret` to connect from the api to the identity provider via the introspection endpoint - this is useful when we use reference token as it allows us to be protected against an unauthorized request possessing a reference token and trying to check the state of the access token. _More info here [https://tools.ietf.org/html/rfc7662](https://tools.ietf.org/html/rfc7662)._

Now that we have configured our API and that it is now protected behind access token validation, we can register it in the identity provider in the api resource section:

```
// -- This is in the Identity provider

public static IEnumerable<ApiResource> GetApiResources()
{
    return new List<ApiResource>
    {
        new ApiResource("api", "Web Api")
        {
            ApiSecrets =
            {
                new Secret("secret".Sha256())
            }
        }
    };
}
```

Every `ApiResource` come with a default scope which is the name of the api. For instance here I named it `api`, therefore I will be able to give to a client `AllowedScopes = { "api" }` which will provide an access token with `Scopes = [ 'api' ]`.

Lastly what we need to do is to configure a client which will be trying to get an access token to access the API.

## 3. Configure a client

A client can be a website or a mobile app or a software client.
In this example I will be creating a Console App and use the `IdentityModel` package to request for an access token.

Let's first start by registering a client in the identity provider:

```
public static IEnumerable<Client> GetClients()
{
    return new List<Client>
    {
        new Client {
            ClientId = "client",
            AllowedGrantTypes = GrantTypes.ResourceOwnerPassword,
            ClientSecrets =
            {
                new Secret("secret".Sha256())
            },
            AllowedScopes = {
                "api"
            }
        }
    }
}
```

Next we create a console app, and add the `IdentityModel` package. We then use the TokenClient to request for a token and we can then use that token to request for the data in the api.
