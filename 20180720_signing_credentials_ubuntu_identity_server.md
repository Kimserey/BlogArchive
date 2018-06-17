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

Generate private key and public key:

```sh
 sudo openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 3650 -nodes -subj "/CN=Expense King Identity"
```

Combine private key and public certificate into `key.pfx` key usable by `dotnet`:

```sh
openssl pkcs12 -export -out key.pfx -inkey key.pem -in key.cer
 ```

 If we already have a .pfx and want to extract the private key `key.pem` and public key `cert.pem`:

 ```sh
 openssl pkcs12 -in key.pfx -nocerts -out key.pem -nodes
 openssl pkcs12 -in key.pfx -nokeys -out cert.pem
 ``` 