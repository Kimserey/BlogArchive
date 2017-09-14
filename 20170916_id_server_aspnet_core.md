# Implicit flow with Identity Server and ASP NET Core

Few months ago I talked about [Resource owner password flow with Identity Server and ASP NET Core](https://kimsereyblog.blogspot.sg/2017/04/resourceownerpassword-with-identity.html). But as mentioned in multi places, ROP is an anti pattern when it comes down to a correct implementation of Open ID Connect. A more appropriate flow for API <-> SPA authentication is the __Implicit flow__. Today we will see how we can implement it in 4 steps:

```
1. Configure Identity server
2. Configure Identity server Login
3. Protect our Api
4. Log in from the JS client
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

Now that we have configured the server, we need to create the Controllers and the pages needed for user interaction. Those pages are the __Login__ and the __Consent__ pages.

## 2. Configure Identity server Login

In order to sign in, we will be redirected to /Account/Login. We start first by creating the account controller which will hold the login endpoint and its models:

```
public class ExternalProvider
{
    public string DisplayName { get; set; }
    public string AuthenticationScheme { get; set; }
}

public class LoginInputModel
{
    [Required]
    public string Username { get; set; }
    [Required]
    public string Password { get; set; }
    public bool RememberLogin { get; set; }
    public string ReturnUrl { get; set; }
}

public class LoginViewModel : LoginInputModel
{
    public IEnumerable<ExternalProvider> ExternalProviders { get; set; }
}
```

And the account controller:

```
public class AccountController : Controller
{
    private readonly IClientStore _clientStore;
    private readonly TestUserStore _users;
    private readonly IIdentityServerInteractionService _interaction;

    public AccountController(IIdentityServerInteractionService interaction, IClientStore clientStore, TestUserStore users)
    {
        _interaction = interaction;
        _clientStore = clientStore;
        _users = users;
    }

    [HttpGet]
    public async Task<IActionResult> Login(string returnUrl)
    {
        var authorizationContext = await _interaction
            .GetAuthorizationContextAsync(returnUrl);

        var client = authorizationContext?.ClientId != null
            ? await _clientStore.FindEnabledClientByIdAsync(authorizationContext.ClientId)
            : null;

        var providers = authorizationContext?.IdP != null ?
            new ExternalProvider[] { new ExternalProvider { AuthenticationScheme = authorizationContext.IdP } }
            : HttpContext
                .Authentication
                .GetAuthenticationSchemes()
                .Where(x => x.DisplayName != null)
                .Where(x => client == null || client != null && client.IdentityProviderRestrictions.Contains(x.AuthenticationScheme))
                .Select(x => new ExternalProvider { DisplayName = x.DisplayName, AuthenticationScheme = x.AuthenticationScheme });

        return View(new LoginViewModel
        {
            ReturnUrl = returnUrl,
            ExternalProviders = providers
        });
    }
}
```

We inject the `IClientStore` which gives us access to the clients configured in Identity server. And we inject `IIdentityServerInteractionService` which is the main service for all interaction like GrantContent, GetAuthorizationContext and ReveokeToken.

In the login endpoint, we start by getting the auhtorization context which gives us the clientId. The clientId then allows us to retrieve the client itself from the client store which we can then use to check for external provider login.

Since all interaction happens from the browser, the easiest way to build the html page is to use the Razor cshtml pages. If you aren't familiar with Razor, I have written an introduction post on Razor few months ago [https://kimsereyblog.blogspot.sg/2017/05/razor-syntax-and-helpers.html](https://kimsereyblog.blogspot.sg/2017/05/razor-syntax-and-helpers.html).

Here is the Login.cshtml page:

```
@model LoginViewModel
@{
    ViewData["Title"] = "Login";
}

<h3 class="text-center m-3">Login</h3>
<div class="card m-auto" style="max-width: 450px">
    <div class="card-body">
        @Html.Partial("_ValidationSummary")
        <form asp-route="Login">
            <input type="hidden" asp-for="ReturnUrl" />
            <div class="form-group">
                <label asp-for="Username"></label>
                <input class="form-control" placeholder="Username" asp-for="Username" autofocus>
            </div>
            <div class="form-group">
                <label asp-for="Password"></label>
                <input type="password" class="form-control" placeholder="Password" asp-for="Password" autocomplete="off">
            </div>
            <div class="form-group login-remember">
                <label asp-for="RememberLogin">
                    <input asp-for="RememberLogin">
                    <span>Remember me</span>
                </label>
            </div>
            <div class="form-group">
                <button class="btn btn-primary btn-block">Login</button>
            </div>
        </form>

        @if (Model.ExternalProviders.Any())
        {
            <ul class="list-inline">
                @foreach (var provider in Model.ExternalProviders)
                {
                    <li>
                        <a class="btn btn-default"
                           asp-action="ExternalLogin"
                           asp-route-provider="@provider.AuthenticationScheme"
                           asp-route-returnUrl="@Model.ReturnUrl">
                            @provider.DisplayName
                        </a>
                    </li>
                }
            </ul>
        }
    </div>
</div>
```

Here we show a login page with username and password with a Remember option. In the event of external providers, we can display those too. The model used on this page is the `LoginViewModel` previously created and returned by the `/Account/Login` endpoint. Now that we have the login page, we can boot the Identity server and navigate to `/Account/Login`.
Next we need to implement the login postback in the controller.

```

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(LoginInputModel model)
        {
            if (ModelState.IsValid)
            {
                var result = _users.ValidateCredentials(model.Username, model.Password);
                if (result)
                {
                    var user = _users.FindByUsername(model.Username);

                    await HttpContext.Authentication.SignInAsync(
                        user.SubjectId, 
                        user.Username,
                        model.RememberLogin ? new AuthenticationProperties
                        {
                            IsPersistent = true,
                            ExpiresUtc = DateTimeOffset.UtcNow.Add(TimeSpan.FromHours(1))
                        }
                        : null
                    );

                    if (_interaction.IsValidReturnUrl(model.ReturnUrl))
                    {
                        return Redirect(model.ReturnUrl);
                    }

                    return RedirectToAction(nameof(HomeController.Index), "Home");
                }

                ModelState.AddModelError("", "Wrong username or password.");
            }

            var providers = ... code to get the providers ...

            return View(new LoginViewModel
            {
                Username = model.Username,
                Password = model.Password,
                ReturnUrl = model.ReturnUrl,
                RememberLogin = model.RememberLogin,
                ExternalProviders = providers
            });
        }
```

Here it is a POST, we also make sure to use the ValidateAntiForgeryToken. When we receive the login data we start by validating using our test user store `_users`, if valid, we sign in from the ASP NET `AuthenticationManager` Api. With that, it is now possible to log in.


## 3. Protect our Api

In order to protect our Api, we dowload the nuget package `IdentityServer4.AccessTokenValidation`.
Then we can place Identity server authentication on the middleware pipeline.

```
app.UseIdentityServerAuthentication(new IdentityServerAuthenticationOptions
{
    Authority = "http://localhost:5000",
    RequireHttpsMetadata = false,
    ApiName = "my-api",
    NameClaimType = "sub"
});
```

We specify the name of our Api and the Authority to whom the calls will be redirected to. We also specify the `NameClaimTyp = "sub"` in order for the subject to be used as the `Name` property to be available in the HttpContext user. We can now protect our Api by using the `[Authorize]` attribute on the controllers and/or actions. Now let's see how we can login from a JS client.

## 4. Log in from the JS client

In order to login from the JS client, we use the `oidc-client` library. Start by installing it with `npm install oidc-client --save`.
Next we can directly make use of the `UserManager` inside a component or a service and use the `signinRedirect()` function to redirect to the OpenID flow.

```
@Component({
  template: `
    <button type="button" (click)="signIn()">Sign In</button>
  `
})
export class AuthTestComponent {
  userManager: UserManager = new UserManager({
    authority: 'http://localhost:5000',
    client_id: 'my-client',
    redirect_uri: 'http://localhost:4200/callback.html',
    response_type: 'id_token token',
    scope: 'openid my-api profile',
    post_logout_redirect_uri: 'http://localhost:4200/index.html',
  });

  signIn() {
    this.userManager.signinRedirect();
  }
}
```

For example here we define the `userManager` by specifying the `client_id`, the `authority` url, the response_type must be `id_token token` and the scope must contain the `openid` scope plus the other scope which this client needs. The redirect_uri is the url which will be called from the server to redirect authententicated users.
For the `callback.html` file, we can simply handle it as followed:

```
<!DOCTYPE html>
<html>
  <head>
      <meta charset="utf-8" />
      <title>Expense King</title>
  </head>
  <body>
      Please wait while we redirect you to Expense King...
      <script src="oidc-client.js"></script>
      <script>
          new Oidc.UserManager()
            .signinRedirectCallback()
            .then(function () { window.location = "/"; })
            .catch(function (e) { console.error(e); });
      </script>
  </body>
</html>
```

And then we can specify this `callback.html` file, plus the `oidc-client` source files as assets:

```
"assets": [
    "assets",
    "favicon.ico",
    "callback.html",
    {
        "glob": "**/*.js",
        "input": "../node_modules/oidc-client/dist/",
        "output": "./"
    }
],
```

If you are unfamiliar with assets, I suggest you take a look at my previous post on [Assets in Angular](https://kimsereyblog.blogspot.sg/2017/09/manage-assets-and-static-files-with.html).

Now when we hit the sign in button we can see that we are redirected to the consent page, which we have not yet created.

## 5. Consent

The consent page allows the user to choose which clients can access their resources. The user identity and the apis being resources protected with sensitive data from the user, it makes sense to ask the user her consent on which to allow and to which client.

_We are using a memory persisted grant store but Identity server also allows us to register our own stores by implementing the IPersistedGrantStore interface._

We start by making view models which we will use in the views:

```
public class ConsentViewModel : ConsentInputModel
{
    public string ClientName { get; set; }
    public string ClientUrl { get; set; }
    public string ClientLogoUrl { get; set; }
    public bool AllowRememberConsent { get; set; }
    public IEnumerable<ScopeViewModel> IdentityScopes { get; set; }
    public IEnumerable<ScopeViewModel> ResourceScopes { get; set; }
}

public class ConsentInputModel
{
    public bool Consent => Convert.ToBoolean(this.ConsentValue);
    public string ConsentValue { get; set; }
    public bool RememberConsent { get; set; }
    public string ReturnUrl { get; set; }
    public IEnumerable<string> ScopesConsented { get; set; }
}

public class ScopeViewModel
{
    public string Name { get; set; }
    public string DisplayName { get; set; }
    public string Description { get; set; }
    public bool Emphasize { get; set; }
    public bool Required { get; set; }
    public bool Checked { get; set; }
}
```

The consent page is accessed through an authenticated redirect to /Consent via a GET. Just like that Login, we start first by building the endpoint.

```
public class ConsentController : Controller
{
    private readonly IClientStore _clientStore;
    private readonly IResourceStore _resourceStore;
    private readonly TestUserStore _users;
    private readonly IIdentityServerInteractionService _interaction;

    public ConsentController(IIdentityServerInteractionService interaction, IClientStore clientStore, IResourceStore resourceStore, TestUserStore users)
    {
        _interaction = interaction;
        _clientStore = clientStore;
        _resourceStore = resourceStore;
        _users = users;
    }
    private async Task<Client> GetClient(string returnUrl)
    {
        var authorizationContext = await _interaction
            .GetAuthorizationContextAsync(returnUrl);

        return authorizationContext?.ClientId != null
            ? await _clientStore.FindEnabledClientByIdAsync(authorizationContext.ClientId)
            : null;
    }

    private async Task<Resources> GetResources(string returnUrl)
    {
        var authorizationContext = await _interaction
            .GetAuthorizationContextAsync(returnUrl);

        return await _resourceStore.FindEnabledResourcesByScopeAsync(
            authorizationContext.ScopesRequested);
    }

    [HttpGet]
    public async Task<IActionResult> Index(string returnUrl)
    {
        var client = await GetClient(returnUrl);
        var resources = await GetResources(returnUrl);

        return View(new ConsentViewModel
        {
            ReturnUrl = returnUrl,
            ClientName = client.ClientName,
            ClientUrl = client.ClientUri,
            ClientLogoUrl = client.LogoUri,
            AllowRememberConsent = client.AllowRememberConsent,
            IdentityScopes = resources.IdentityResources.Select(id =>
            {
                return new ScopeViewModel
                {
                    Name = id.Name,
                    DisplayName = id.DisplayName,
                    Description = id.Description,
                    Emphasize = id.Emphasize,
                    Required = id.Required,
                    Checked = true
                };
            }),
            ResourceScopes = resources.ApiResources.SelectMany(x => x.Scopes).Select(id =>
            {
                return new ScopeViewModel
                {
                    Name = id.Name,
                    DisplayName = id.DisplayName,
                    Description = id.Description,
                    Emphasize = id.Emphasize,
                    Required = id.Required,
                    Checked = true
                };
            })
        });
    }
}
```

Next we can build the cshtml page to display the consent:

```
@model ConsentViewModel

<div class="card m-auto" style="max-width: 450px">
    <div class="card-body">
        <p>
            <strong>@Model.ClientName</strong> would like to access:
        </p>

        @Html.Partial("_ValidationSummary")

        <form asp-action="Index">
            <input type="hidden" asp-for="ReturnUrl" />

            @if (Model.IdentityScopes.Any())
            {
                @foreach (var scope in Model.IdentityScopes)
                {
                    @Html.Partial("ScopeItem", scope)
                }
            }

            @if (Model.ResourceScopes.Any())
            {
                <ul class="list-group">
                    @foreach (var scope in Model.ResourceScopes)
                    {
                        @Html.Partial("ScopeItem", scope)
                    }
                </ul>
            }

            @if (Model.AllowRememberConsent)
            {
                <div class="my-2 text-right">
                    <label asp-for="RememberConsent">
                        <input asp-for="RememberConsent" />
                        Remember my decision
                    </label>
                </div>
            }

            <div class="text-right">
                <button name="consentValue" value="false" class="btn">Deny</button>
                <button name="consentValue" value="true" class="btn btn-primary" autofocus>Accept</button>
                @if (Model.ClientUrl != null)
                {
                    <a class="pull-right btn btn-default" target="_blank" href="@Model.ClientUrl">
                        <strong>@Model.ClientName</strong>
                    </a>
                }
            </div>
        </form>
    </div>
</div>
```

Where each scope item is a partial view:

```
@model ScopeViewModel

<div>
    <input class="d-inline" type="checkbox" name="ScopesConsented" id="scopes_@Model.Name" value="@Model.Name" checked="@Model.Checked" disabled="@Model.Required" />
    @Model.DisplayName
    @if (Model.Required)
    {
        <input type="hidden" name="ScopesConsented" value="@Model.Name" />
    }
    @if (Model.Required)
    {
        <span><em>(required)</em></span>
    }

    @if (Model.Description != null)
    {
        <em for="scopes_@Model.Name"> - @Model.Description</em>
    }
</div>
```

Now that we have that, once logged in, we should be redirected to the consent page but we can't approve yet as we have not yet build the POST.
Finally we add a support to the postback of consents:

```
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> Index(ConsentInputModel model)
{
    if (model.Consent)
    {
        if (!_interaction.IsValidReturnUrl(model.ReturnUrl)
            || model.ScopesConsented == null
            || !model.ScopesConsented.Any())
        {
            return View("Error");
        }

        var authorizationContext = await _interaction
            .GetAuthorizationContextAsync(model.ReturnUrl);

        if (authorizationContext == null)
        {
            return View("Error");
        }

        var request = await _interaction.GetAuthorizationContextAsync(model.ReturnUrl);
        await _interaction.GrantConsentAsync(request, new ConsentResponse
        {
            RememberConsent = model.RememberConsent,
            ScopesConsented = model.ScopesConsented
        });
        return Redirect(model.ReturnUrl);
    }
    else
    {
        var authorizationContext = await _interaction
        .GetAuthorizationContextAsync(model.ReturnUrl);

        var request = await _interaction.GetAuthorizationContextAsync(model.ReturnUrl);

        await _interaction.GrantConsentAsync(request, ConsentResponse.Denied);
        return Redirect(model.ReturnUrl);
    }
}
```

Here we Grant consent when the model is valid or we deny if the user pressed deny. We can then post back the consent to store those. The identity server part is now done.
Once the user grants access, Identity server redirect to the callback url and the token is set in the session storage and accessible through the `oidc-client`.
And that's it we are done for the Login part of the Implicit flow. Here we used test users, memory persisted grant and memory clients and resources, in the future we will see how we can use Identity Core to abstract away the complexity of identity handling, we will also see how we can use Entity Framework to store grants and resources.

Code is available on my GitHub:

 -[Server: https://github.com/Kimserey/identity-server-sample/tree/master/Identity](https://github.com/Kimserey/identity-server-sample/tree/master/Identity)
 -[Client: https://github.com/Kimserey/ng-samples/blob/master/src/app/auth/auth-test.ts](https://github.com/Kimserey/ng-samples/blob/master/src/app/auth/auth-test.ts)

# Conclusion

Today we saw how to implement the Implicit Flow with Identity Server. This flow is particularly useful for SPAs as the redirect and handling of authentication allows us to have a single place to manage identities for multiple Apis and multiple clients. We saw what sort of endpoints and screens must be created to support the login feature and we saw how we could configure the JS SPA client in Angular to handle the login redirect. Hope you liked this post as much as I enjoyed writting it. As usual if you have any questions, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!