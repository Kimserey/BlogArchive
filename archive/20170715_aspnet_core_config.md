# Configurations in ASP NET Core

Every application needs configurations, whether it is a port, or a path or simply string values. In order to deal with configurations, ASP NET Core ships with a Configuration framework. The framework provides a builder allowing to read configurations from different json files, supports environment convention and also defining custom configuration providers in order to read from other sources like MSSQL or other services.
Today we will see how we can use the configuration framework.

This post will be composed by 2 parts:

```
1. Install the configuration framework
2. Make configuration injectable via Options
```

# 1. Install the configuration framework

We start first by making sure we have the library installed, `Microsoft.Extensions.Configuration`.
In Startup constructor use the `ConfigurationBuilder` to extract configurations:

```
public IConfigurationRoot Configuration { get; set; }

public Startup(IHostingEnvironment env)
{
    var builder = new ConfigurationBuilder()
        .SetBasePath(Directory.GetCurrentDirectory())
        .AddJsonFile("appsettings.json");

    Configuration = builder.Build();
}
```

We start to intantiate a `ConfigurationBuilder` in `Startup` which we define the base path to get our json config files and then register our `appsettings.json` config file.

What we can do now is use the configuration to initialize services. For example if we have the following configuration which contains a port:

```
{
    "endpoint": {
        "address": "locahost",
        "port": 5000
    }
}
```

We can then make use of the `Configuration` built to instantiate a service:

```
services.AddTransient<IMyService>(_ => new MyService(Configuration.GetSection("endpoint").Get<Endpoint>()));
```

_Do not confuse `Get<>()` with `GetValue<>()` as the latest is for simple scenarios and does not bind to entire sections._

Lastly the configuration framework supports a tree navigation which allows to get to entire child sections, including values:

```
var port = Configuration.GetSection("endpoint:port").Get<int>();
```

Using the configuration to initialize services in `Startup.cs` is one way of using the configuration. The second way is to make pieces of the configuration injectable via dependency injection anywhere in the system. This can be done using `Options`.

# 2. Make configuration injectable via Options

Consider the following `appsettings.json` content:

```
{
  "Constant": "Hello world",
  "OneTwo": {
    "One": "One",
    "Two": "Two"
  }
}
```

And the following option class:

```
public class MyConfig
{
    public string Constant { get; set; }
    public OneTwo OneTwo { get; set; }

    public class OneTwo
    {
        public string One { get; set; }
        public string Two { get; set; }
    }
}
```

We can then use the options by first adding the Options framework in the service configuration with `.AddOptions()` and using the extension `.Configure<>` to configure and make available the `MyConfig` class and `OneTwo`:

```
public void ConfigureServices(IServiceCollection services)
{
    services.AddOptions();
    services.Configure<MyConfig>(this.Configuration);
    services.Configure<OneTwo>(this.Configuration.GetSection("Option"));
    services.AddMvc();
}
```

After doing that, the configuration becomes injectable as any other services given by the service provider anywhere in constructor or in controller endpoints with `[FromServices]`:

```
public IActionResult Get([FromServices] IOptions<MyConfig> options)
{
    return Json(options.Value);
}

public IActionResult GetOneTwo([FromServices] IOptions<OneTwo> options)
{
    return Json(options.Value);
}
```

The official documentation can be found here [https://docs.microsoft.com/en-us/aspnet/core/fundamentals/configuration](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/configuration)

# Conclusion

The configuration framework with the options is a very convenient way to maintain configurations. It combines the flexibility of a configuration file with the json settings together with the type safety of a C# class all done within a trusted framework. Hope you like this post as much I liked writting it! If you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!