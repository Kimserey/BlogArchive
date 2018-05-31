# Manage configurations with ASP NET Core on Ubuntu

Managing configurations can be challenging. We cannot simply check-in in our repository secrets and connection strings and at the same time we want an easy way to maintain them.
Today we will see how we can manage secrets is am easy way on Ubuntu with systemd.

1. Make secrets available on server with systemd
2. Manage secrets locally with UserSecrets on ASP NET Core
3. Manage UserSecrets for dotnet Console Application

## Goal

We need to keep secrets out of the source code. Therefore we want to have our application get secrets locally for local testing and we want the application to get them in our hosted environment.
In order to achieve that we will use systemd override configuration to hold configuration of secrets on our server and in our local machine we will use UserSecrets which holds configurations in the user app folder.

*Take note that UserSecrets file is not encrypted. The only protection we get is the OS user protection.*

If you are not familiar with systemd, checkout my previous blog post on [How to manage Kestrel process with systemd](https://kimsereyblog.blogspot.com/2018/05/manage-kestrel-process-with-systemd.html).

## 1. Make secrets available on server with systemd

Using systemd unit configuration file, it is possible to add environment variables under `[Service]`. But environment variables for configuration are likely to change hence it is better to keep them separated from the whole unit file.

To achieve that, we can use the override from systemd by doing the following:

```sh
systemctl edit /etc/systemd/system/myapp.service
```

We are then brought to a file which is the override file for `myapp.service`. Inside this file we can add our variables

```sh
[Service]
Environment=MY_VAR_ONE=secret1
Environment=MY_VAR_TWO=secret2
```

This has the advantage to reduce errors as we will have a focused file for updates of configuration and the main unit file which configure how the process is managed is kept separate. So we can think of it as "infrastructure configuration", how is the process handled, who is the user running the app, what command is ran, this is the main service file versus "application configuration", secrets, connection strings, this is the override file.

## 2. Manage secrets locally with UserSecrets on ASP NET Core

When we use the configuration file from systemd, we leave those configurations out of our source code. But when we run locally, we need way to have secrets setup locally.

ASP NET Core comes configured with `UserSecrets` functionality which also setup to work with Visual Studio. To access it, right click on application project and select manage user secret. We will be brought to a json file which we can modify just like how we add configuration in appsettings.

```json
{
    "test": "test"
}
```

Or we can also use the CLI with `secret` to add, delete or list secrets.

```sh
dotnet user-secrets list
```

If the command does not work, we can install the library `Microsoft.Extensions.SecretManager.Tools` and add the `ItemGroup` in the .csproj:

```xml
<ItemGroup> <DotNetCliToolReference Include="Microsoft.Extensions.SecretManager.Tools" Version="1.0.1" /> </ItemGroup>
```

Those secrets are actually stored in a file located in app data user under `%APPDATA%\Microsoft\UserSecrets\<user_secrets_id>\secrets.json` where the user secret id can be found in the csproj.

When the project runs, the secrets are filled in the configuration object thanks to the user secretd configuration provider which is registered by default to the webhost builder.

## 3. Manage UserSecrets for dotnet Console Application

For console application, the user secrets library is not setup.

Just like in the web project, we can start by making the CLI work by installing the library `Microsoft.Extensions.SecretManager.Tools` and enabling it in the csproj:

```xml
<ItemGroup> <DotNetCliToolReference Include="Microsoft.Extensions.SecretManager.Tools" Version="1.0.1" /> </ItemGroup>
```

Because the user secrets works per project, it uses a GUID which needs to be defined in the project property.

```xml
<PropertyGroup> <TargetFramework>netcoreapp2.1</TargetFramework> <UserSecretsId>a random guid</UserSecretsId> </PropertyGroup>
```

This GUID will point to the folder where the secret.json file will be stored which we can create now under `%APPDATA%\Microsoft\UserSecrets\<user_secrets_id>\secrets.json`.

Under `/UserSecrets` we can see all our projects secrets.

Lastly we need to register the user secrets provider in order to fill up the configuration with the secrets.

```c#
class Program
{
    static void Main(string[] args)
    {
        var builder = new ConfigurationBuilder()
            .AddUserSecrets<Program>()
            .Build();

        // ...
    }
}
```

Now when we run the console app, we should have the secrets injected in the configuration.

## Conclusion

Today we saw how we could keep secrets and connection strings out of the source code while still providing an easy way to maintain them on the server. We also saw how we could do the same on our local environment using UserSecrets library for both web and console app project. Hope you liked this post, see you next time!