# How to use the configuration API in ASP NET Core

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

Using the configuration to initialize services in `Startup.cs` is one way of using the configuration. The second way is to make pieces of the configuration injectable via dependency injection anywhere in the system. This can be done using `Options`.

# 2. Make configuration injectable via Options

Consider the following `appsettings.json` content:

```
{
  "Constant": "Hello world",
  "Option": {
    "One": "One",
    "Two": "Two"
  }
}
```


```
public class ConstantAndOption
{
    public string Constant { get; set; }
    public OneTwoOption Option { get; set; }

    public class OneTwoOption
    {
        public string One { get; set; }
        public string Two { get; set; }
    }
}
```

```
public void ConfigureServices(IServiceCollection services)
{
    services.AddOptions();
    services.Configure<ConstantAndOption>(this.Configuration);
    services.Configure<OneTwoOption>(this.Configuration.GetSection("Option"));
    services.AddMvc();
}
```

```
public IActionResult Get([FromServices] IOptions<ConstantAndOption> options)
{
    return Json(options);
}
```

```
[HttpGet("onetwo")]
public IActionResult Get([FromServices] IOptions<OneTwoOption> options)
{
    return Json(options);
}
```