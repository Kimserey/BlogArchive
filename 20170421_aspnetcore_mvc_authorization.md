# Authorization in ASP.NET Core

Last week I touched on how we could authenticate users using Resource Owner Password flow with identity server. Authentication is the act of taking the information provided and verifying the "identity" of the user, ensuring that Alice (our beloved example user) is who she "claims" to be.
In the program itself, we take her credentials and verify it and create and identity stating that the user is Alice and has claims A, B and C.

Authentication is the first part of the access security, the second part is the authorization. The difference being that for authorization, we know who the user is, what we are verifying is if Alice is allowed to perform what she is trying to perform. The easiest example is the difference between user access and admin access commonly seen in software where users are authenticated but aren't authorized to perform all the actions available in the system.

ASP.NET Core comes with a set of useful tools to perform authorization. Today I will give examples on how we can use the different interfaces and services provided to quickly build authorization.
This post will be composed by 4 parts:

1. Setup the test
2. Role-based authorization
3. Claim-based authorization
4. Policy-based authorization
5. Resource-based authorization

## 1. Setup the test

In order to test our authorization we would need a test example.
The quickest way is to have a jwt middleware which automatically authenticate and create an endpoint directly giving a valid token with claims. We start by creating a web api project and add the jwt authorization library:

```
Microsoft.AspNetCore.Authentication.JwtBearer
```

Then we add an endpoint for the token

```
using System.IdentityModel.Tokens.Jwt;

[Route("api/[controller]")]
public class TokenController : Controller
{
    [HttpGet]
    public IActionResult Get()
    {
        var claims = new Claim[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, "alice"),
        };

        var jwt = new JwtSecurityToken(claims: claims);
        var encodedJwt = new JwtSecurityTokenHandler().WriteToken(jwt);

        return Json(encodedJwt);
    }
}
```

Next we protect the api with the Jwt bearer authentication, done from the `Startup.cs`:

```
public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory)
{
    loggerFactory.AddConsole(Configuration.GetSection("Logging"));
    loggerFactory.AddDebug();

    var tokenValidationParameters = new TokenValidationParameters
    {
        // Disable all token integrity validations
        ValidateIssuer = false,
        ValidateAudience = false,
        ValidateLifetime = false,
        ValidateIssuerSigningKey = false,
        ValidateActor = false,
        RequireSignedTokens = false,
        NameClaimType = JwtRegisteredClaimNames.Sub,
        RoleClaimType = "roles"
    };

    // Remove all automatic mapping for inbound claims
    // Otherwise "sub" becomes "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"
    JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

    app.UseJwtBearerAuthentication(new JwtBearerOptions
    {
        AutomaticAuthenticate = true,
        TokenValidationParameters = tokenValidationParameters
    });

    app.UseMvc();
}
``` 

We disable all check on the token to trust every token given for our testing as we only are going to try out authorization.

`AutomaticAuthenticate` is used to indicate that we want the middleware to straight take the bearer token and deserialize it into a user principal and set it to the `User` property in the `HttpContext` for it to be available in the controller. 

Next we simply test by adding the Authorize attribute. You can also check the user on the HttpContext, it should be set to Alice.

```
[HttpGet]
[Authorize]
public string Get()
{
    var subject = HttpContext.User.Claims.Single(claim => claim.Type == JwtRegisteredClaimNames.Sub);
    return $"{subject.Value} is authorized!";
}
```

## 2. Role-based authorization

Mvc also provides an easy way to add role authorization by passing the role name in the attribute itself.

```
[HttpGet("report")]
[Authorize(Roles = "user")]
public string GetReport()
{
    return $"{HttpContext.User.Identity.Name} is authorized!";
}
```

Our endpoint will not be accessible for Alice. We need to give her the claim. Multiple roles can be given by setting the claim multiple time.

```
var claims = new Claim[]
{
    new Claim(JwtRegisteredClaimNames.Sub, "alice"),
    new Claim("roles", "admin"),
    new Claim("roles", "user")
};
```

Lastly, since we removed the inbound claim type map `JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();`, ASP.NET is looking for the wrong role claim name. We need to make sure we have specified which claim is used to deserialize the roles in the `TokenValidationParameters` option in `Startup.cs`:

```
RoleClaimType = "roles"
```

## 3. Claim-based authorization

A claim is a property of Alice which defines her, who she is in regards to our system.
The most obvious one is that she claims to be Alice. This translates to a claim "sub:alice" for subject.
If she claims to be an admin she will have a claim "roles:admin".

We can have claims more oriented toward our business logic, for example if we have a set of reports in our application, we could only let user access reports if they have the `accesses` claim with a value of `report`.

In order to achieve this example, we need to configure a policy requiring the claims `roles:user` and `accesses:report`.

```
[Authorize(Policy = "hasReportAccess")]
```

In order to do so we define a policy:

```
public void ConfigureServices(IServiceCollection services)
{
    services.AddAuthorization(opt =>
    {
        opt.AddPolicy("hasReportAccess", 
            policy => policy
                .RequireClaim("accesses", "report")
                .RequireRole("user"));
    });

    services.AddMvc();
}
```

Now we should be able to access the endpoint if Alice has the right claims:

```
var claims = new Claim[]
{
    new Claim(JwtRegisteredClaimNames.Sub, "alice"),
    new Claim("roles", "admin"),
    new Claim("roles", "user"),
    new Claim("accesses", "report")
};
```

## 4. Policy-based authorization

In claim-based we saw a glimpse of policy. A policy is a requirement (or mutiple requirements) to fulfill.
Role and claim based authorization are constructed on top of policies. What a policy allows us to do is to add multiple requirements for example we could require a role of "roles:user" and some other claims like "accesses:report" and name the policy "hasReportAccess".


Policies also allow more advanced scenario by defining `requirements` and `handlers`.
We can define a policy requirement like so:

```
public class OfficeHoursRequirement : IAuthorizationRequirement
{
    public OfficeHoursRequirement(int start, int end)
    {
        Start = start;
        End = end;
    }

    public int Start { get; private set; }
    public int End { get; private set; }
}
```

And add a `handler` to be invoked when an endpoint protected by the policy is accessed:

```
public class OfficeHoursRequirementHandler : AuthorizationHandler<OfficeHoursRequirement>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context, 
        OfficeHoursRequirement requirement)
    {
        var now = DateTime.Now;

        if (now.Hour >= requirement.Start && now.Hour <= requirement.End)
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}
```

If the requirement is successful, the authorization will succeed. In contrary if we simply return without succeeding, the next requirement in the pipeline will be invoke. This behavior allows OR logic with requirements.
If for any reason you wish to fail the authorization, it is also possible to call fail and prevent other requirements to succeed.

Then we can register the policy in `Startup.cs`:

```
services.AddAuthorization(opt =>
{
    opt.AddPolicy("hasReportAccess", 
        policy => policy
            .RequireClaim("accesses", "report")
            .RequireRole("user"));

    opt.AddPolicy("accessibleOnlyDuringOfficeHours", 
        policy => policy.AddRequirements(new OfficeHoursRequirement(8, 17))
            .RequireClaim("accesses", "report")
            .RequireRole("user"));
});
```

## 5. Resource-based authorization

The last authorization is resource-based which also make use of policies but, as its name states it, require the resource to perform the authorization.
A typical scenario would be if we need to retrieve a value and check properties against the value before being able to decide whether or not the user has the rights to act on the value.

For example, Alice wants to modify a financial report. She might only be able to modify it if she authored it. Therefore we would need to retrieve the report and check if Alice is the author of it.

```
[HttpPut("report/{id}")]
public async Task<IActionResult> PutReport(string id)
{
    // Get the resource from somewhere
    var report = new Report { Author = "alice", Content = "" }; 
    
    if (await _authorizationService.AuthorizeAsync(HttpContext.User, report, new AuthorRequirement()))
    {
        return Ok();
    }
    else
    {
        return Unauthorized();
    }
}
```

We could do that with a if-else within the controller but Mvc provides an `authorizationService` which can be injected in the controller.
This allows us to authorize the request and give in the resource.

Similarly as policies we create a requirement and we create a handler to handle the requirement. The difference this time is that we implement the authorization handler with the resource type.

```
public class AuthorRequirement : IAuthorizationRequirement { }

public class AuthorRequirementHandler : AuthorizationHandler<AuthorRequirement, Report>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        AuthorRequirement requirement,
        Report resource)
    {
        if (context.User.Identity.Name == resource.Author)
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}
```

You might be thinking why would we use a if-else on the authorization service when we can use a if-else to directly check the property. The reason is that we can have multiple handlers checking for the same requirement again similar to policies where we want to implement an OR logic where one of the handler can pass the requirement. Another reason is that the logic of the authorization would be in a single place, in the handlers, for the requirements which avoid having the check logic spread in multiple controller endpoints.

# Conclusion

We saw the different types of authorization available in ASP.NET Core and the reason why we should use those. It is important to understand all the authorization types provided by the framework since there isn't one type which can fit all use cases. Hope you enjoyed this post as much as I enjoyed writing it! If you have any question leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Links

- Example source code - [https://github.com/Kimserey/authorization-samples](https://github.com/Kimserey/authorization-samples)
- ASP.NET Core authorization documentation - [https://docs.microsoft.com/en-us/aspnet/core/security/authorization/introduction](https://docs.microsoft.com/en-us/aspnet/core/security/authorization/introduction)
- ASP.NET Core repository - [https://github.com/aspnet/Mvc](https://github.com/aspnet/Mvc)