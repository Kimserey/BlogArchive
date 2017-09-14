# Implicit flow with Identity Server and ASP NET Core

Few months ago I talked about [Resource owner password flow with Identity Server and ASP NET Core](https://kimsereyblog.blogspot.sg/2017/04/resourceownerpassword-with-identity.html). But as mentioned in multi places, ROP is an anti pattern when it comes down to a correct implementation of Open ID Connect. A more appropriate flow for API <-> SPA authentication is the __Implicit flow__. Today we will see how we can implement it in 4 steps:

```
1. Configure Identity server
2. Configure Identity server redirects pages
3. Protect the API
4. Authenticate on the client
```

## 1. Configure Identity server

With the Implicit flow, all the authentication process happens through the browser. The user will be redirected to a login page delivered by the Identity server, then the redirect authentication will all taken place within the Identity server.
For our example, we will be using the test users and will only be demonstrating login. 

We start first by creating a ASP NET Core 1.1 web application which will host our Identity server instance. _We use 1.1 for the moment as the support for 2.0 is in rc-1 as of now. There will be breaking changes but the protocol remains the same therefore the understanding will still be valid._

We start first by configuring the server on the `Startup.cs` in the `ConfigureServices`:

```
services.AddIdentityServer()
    .AddTemporarySigningCredential()
    .AddInMemoryIdentityResources(new List<IdentityResource> {
        new IdentityResources.OpenId(),
        new IdentityResources.Profile(),
        new IdentityResources.Email()
    })
    .AddInMemoryApiResources(new[] {
        new ApiResource("my-api", "My Api")
    })
    .AddInMemoryClients(new[] {
        new Client
        {
            ClientId = "my-client",
            ClientName = "My Client",
            AllowedGrantTypes = GrantTypes.Implicit,
            AllowAccessTokensViaBrowser = true,
            AllowedCorsOrigins = { "http://localhost:4200" }, // My Client is a Angular application served on port 4200
            AllowRememberConsent = true,
            AllowedScopes =
            {
                IdentityServerConstants.StandardScopes.OpenId,
                IdentityServerConstants.StandardScopes.Profile,
                IdentityServerConstants.StandardScopes.Email,
                "my-api"
            },
            RedirectUris = { "http://localhost:4200/callback.html" },
            PostLogoutRedirectUris = { "http://localhost:4200/index.html" }
        }
    })
    .AddTestUsers(new List<TestUser> {
        new TestUser {
            SubjectId = "alice",
            Username = "Alice",
            Password = "12345",
            Claims = {
                new Claim(IdentityServerConstants.StandardScopes.Email, "alice@gmail.com"),
                new Claim(IdentityServerConstants.StandardScopes.Address, "21 Jump Street")
            }
        }
    });
```

We allow access to 3 identity scopes, `OpenId` which is required, `Profile` and `Email`. Those will be available for allowed clients to access. Next we define a resource API with a single scope `my-api`, by creating a ApiResource using the constructor `new ApiResource("","")`, a scope is automatically created. Then we create a client, `my-client` which we allow to access the scopes defined from the identity and the api. Other settings are set for redirect urls. Lastly we define use a test user for our example where we define two claims, an email claim and an address claim which is part of the profile.

Then we use identity server inside `Configure`:

```
public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory)
{
    loggerFactory
        .AddConsole(Configuration.GetSection("Logging"))
        .AddDebug();

    app.UseDeveloperExceptionPage();
    app.UseStaticFiles();
    app.UseIdentityServer();
    app.UseMvcWithDefaultRoute();
}
```

Now that we have configured the server, we need to create the Controllers and the pages needed for user interaction. Those pages are the __Login__ and the __Consent__ pages:

## 2. Configure Identity server redirects pages