# Setup environments for your AspNetCore backend and Angular frontend

Last week we saw how we could use angular cli and dotnet cli to pack and publish our application with simple commands. The application had no settings therefore there wasn't a need to differentiate multiple deployments. But if we do need different settings, how should we handle it?
Today I will amswer this question by explaining how we can setup targets and environments for our application. This post will be composed by three parts:

```
1. What is the difference between a target and an environment
2. Setup target and nvironment settings for AspNetCore app
3. Setup target and environment settings for Angular CLI
```

## 1. What is the difference between a target and an environment

A target refers to a target build. A target build is a set of configurations used to build the application. For development, the optimization is usually disabled as build time is more important than the optimization of code for example which would slow down the build time. Other configurations can be set like the architecture and platform targeted.
In Visual Studio the target is the build configuration which can be set through the property of the project.
In Angular CLI there are two predefined targets, dev and prod.

An environment refers to a global context where the application runs. The most common environments for Software Development are:

```
1. Development
2. Integration
3. UAT
4. Staging
5. Production
```

Environments embody a set of settings. For example backend url, cdn activation, load balancing, instance counts, database connection strings and many more.
For example running our application under development environment, we would connect to localhost database.

Integration environment refers to the environments where all code get integrated during Continuous Integration where merge conflicts resolution with pull requests mergers can be tested properly.

Environment does not just refer to settings. When we talk about environment, we refers to the code deployed, the infrastructure holding the deployment, the type of users using the application and of course the settings tied to it. It is the whole context where the application lives.

## 2. Setup target and nvironment settings for AspNetCore app

By default in Visual Studio, two targets are predefined, Debug and Release. The differences can be found in the property of the projects.

When building or publishing the application, it can be selected using the switch `dotnet publish -c Debug` or `dotnet publish -c Release` and the correct build configurations will be used.

For environment settings, AspNetCore has always supported multiple appsettings. All we need to do is create multiple appsettings file targeted to our environments and overwrite the main appsettings settings by only specifying those in the specific appsettings.

```
appsettings.json
appsettings.production.json
appsettings.integration.json
```

The content of the configuration file is a json object.

The environment is selected at runtime. It is set via system environment variable for the application but can also be passed as command line argument.
Make sure that your configuration has the command line argument on its builder pipeline.
In AspNetCore 2.x.x, if you are using `CreateDefaultBuilder`, it will be addes by default.

This is the source code of `CreateDefaultBuilder` [(source)](https://github.com/aspnet/MetaPackages/blob/dev/src/Microsoft.AspNetCore/WebHost.cs):

```
ConfigureAppConfiguration((hostingContext, config) =>
{

    var env = hostingContext.HostingEnvironment;

    config.AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
        .AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: true, reloadOnChange: true);

    if (env.IsDevelopment())
    {
        var appAssembly = Assembly.Load(new AssemblyName(env.ApplicationName));
        if (appAssembly != null)
        {
            config.AddUserSecrets(appAssembly, optional: true);
        }
    }
    config.AddEnvironmentVariables();
    if (args != null)
    {
        config.AddCommandLine(args);
    }
}
```

Then all we need to do is specify the en vironment via argument:

```
dotnet run --environment=integration
```

Or for a deployed app:

```
dotnet x.dll --environment=integration
```

That's how we can setup and use multiple targets and environments in Visual Studio and dotnet.

## 3. Setup target and environment settings for Angular CLI

In Angular CLI, there are two predefined targets. Dev and prod, they set different configurations for the build itself. The differences of configuration can be found [here](https://github.com/angular/angular-cli/blob/master/docs/documentation/build.md#--dev-vs---prod-builds). The target can be selected for the build using `--dev` or `--prod`.

```
ng build --prod
```

For the environment settings, Angular CLI supports having multiple evironment files which are used to set the all settings.
Similarly as AspNetCore, we can have the following:

```
environment.ts
environment.integration.ts
environment.production.ts
```

The content of the environment file is a simple object.

And those will defines settings which will be used depending on the environment selected.
The mapping from keyword to file must be set in the `.angular-cli.json` file under environments:

```
"environments": {
    "dev": "environment.ts",
    "prod": "environment.production.ts",
    "integration": "environment.integration.ts"
}
```

The difference between Angular CLI and dotnet is that the environment needs to be given for the build. This is due to the fact that ultimately, the code is transpiled to JS and bundled together with the settings employed. So the selection happens at build time.

To set an environment, we use the switch `--env`:

```
ng build --prod --env=prod
```

And that's it once we build, we will have an application ready to be deployed under the right environment.

# Conclusion

Today we saw how we could set targets for builds to enable build time configurations. We also saw how to configure different environments for the application to run using different settings. Using this methods we can setup multiple environments to run our application. Hope you like this post as much as I liked writing it. See you next time!