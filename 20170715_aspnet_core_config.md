# How to use the configuration API in ASP NET Core

Add Microsoft.Extensions.Configuration

In Startup constructor use the `ConfigurationBuilder` to extract configurations:

```
public Startup(IHostingEnvironment env)
{
    var builder = new ConfigurationBuilder()
        .SetBasePath(Directory.GetCurrentDirectory())
        .AddJsonFile("appsettings.json");

    Configuration = builder.Build();
}

public IConfigurationRoot Configuration { get; set; }
```

In the `ConfigureServices`, we can then add options.

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