# Create signing credentials for Identity Server 4 in Ubuntu 16.04 server

To sign our JWT tokens, Identity Server 4 requires a signing credential. Today we will see how we can create our own key and provide it to Identity Server to be used as signing credential.

1. Configure ASP NET Core
2. Create key with `openssl`

If you are new to Identity Server, you can have a look at my previous blog post on [How to configure a Implicit authentication with Identity Server](https://kimsereyblog.blogspot.com/2017/09/implicit-flow-with-identity-server-and.html?m=1).

## 1. Configure ASP NET Core

We start first by creating an extension on top of the `IIdentityServerBuilder` which when the key is available, will load our own key using the `.AddSigningCredential()` else will create a temporary key for development purposes,  `.AddDeveloperSigningCredential()`. 

```c#
public static class IdentityServerBuilderExtensions
{
    public static IIdentityServerBuilder LoadSigningCredentialFrom(this IIdentityServerBuilder builder, string path)
    {
        if (!string.IsNullOrEmptyString(path))
        {
            builder.AddSigningCredential(new X509Certificate2(path));
        }
        else
        {
            builder.AddDeveloperSigningCredential();
        }

        return builder;
    }
}
```

Using the configuration `appsettings.production.json`, we add a `signingCredential` section.

```json
"signingCredential": {
    "path": "/etc/myapp/key.pfx"
}
```

We did not add the section in the `appsettings.development.json` therefore it will be `null` in development which is what we want for Identity Server to use the temporary key. Next we use the extension in the `Startup.cs` where we configured Identity Server:

```c#
var identityServerBuilder = services
    .AddIdentityServer()
    .LoadSigningCredentialFrom(
      Configuration.GetSection("identityServer:signingCredential:active").Get<bool>(),
        Configuration["identityServer:signingCredential:path"]
    )
    .AddInMemoryIdentityResources(...)
    .AddInMemoryApiResources(...)
    .AddInMemoryClients(...)
    .AddAspNetIdentity<ApplicationUser>();
```

Now that we are loading the key from a physical path, we can create the key.

## 2. Create key with `openssl`

To generate the key we will be using `openssl` on Ubuntu 16.04. We start firt by generating the private key `key.pem` and public certificate `cert.pem`:

```sh
sudo openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 3650 -nodes -subj "/CN=Expense King Identity"
```

Next we combine them into a key `key.pfx` usable by `dotnet`:

```sh
openssl pkcs12 -export -out key.pfx -inkey key.pem -in key.cer
```

The resulting `.pfx` is the file which can be used to instantiate a `X509Certificate2` object we needed in 1).

If we already have a .pfx and want to extract the private key `key.pem` and public key `cert.pem`:

```sh
openssl pkcs12 -in key.pfx -nocerts -out key.pem -nodes
openssl pkcs12 -in key.pfx -nokeys -out cert.pem
``` 

And this concludes today's post.

## Conclusion

Today we saw how we could register our own key to be used to sign our tokens delivered by Identity Server. We started by configuring Identity Server to use the key if we pass the path to it else use a development key. And we completed the post by creating that key using `openssl`. Hope you liked this post, see you next time!