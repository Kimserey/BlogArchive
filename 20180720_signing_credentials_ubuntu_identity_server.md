# Create signing credentials for Identity Server in Ubuntu 16.04 server

```c#
public static class IdentityServerBuilderExtensions
{
    public static IIdentityServerBuilder AddSigningCredentialIf(this IIdentityServerBuilder builder, bool predicate, string privateKeyFilePath)
    {
        if (predicate)
        {
            builder.AddSigningCredential(new X509Certificate2(privateKeyFilePath));
        }
        else
        {
            builder.AddDeveloperSigningCredential();
        }

        return builder;
    }
}
```

```json
"signingCredential": {
    "active": false
}
```

```json
"signingCredential": {
    "active": true,
    "path": "/etc/ek/key.pfx"
}
```

```c#
var identityServerBuilder = services
    .AddIdentityServer()
    .AddSigningCredentialIf(
        Configuration.GetSection("identityServer:signingCredential:active").Get<bool>(),
        Configuration["identityServer:signingCredential:path"]
    )
    .AddInMemoryIdentityResources(...)
    .AddInMemoryApiResources(...)
    .AddInMemoryClients(...)
    .AddAspNetIdentity<ApplicationUser>();
```

```sh
 # Generate Private key 'key.pem' and public certificate 'key.cer'
 sudo openssl req -x509 -newkey rsa:4096 -keyout key.pem -out key.cer -days 3650 -nodes -subj "/CN=Expense King Identity"
```

```sh
 # Combine private key and public certificate into pfx key usable for dotnet
 sudo openssl pkcs12 -export -out key.pfx -inkey key.pem -in key.cer
 ```