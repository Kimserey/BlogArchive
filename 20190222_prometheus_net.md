# Prometheus for ASP NET Core

[Prometheus](https://prometheus.io/) is an open source monitering platform. It provides multiple functionalities to store, manipulate and monitor metrics from our applications. Today we will see how we can push metrics from an ASP NET Core application, and how to make sense of it.

1. Setup Prometheus locally for testing
2. Push metrics from ASP NET Core
3. Analyse metrics with Grafana dashboard

## 1. Setup Prometheus locally for testing

To setup Prometheus we download it directly from the [official website](https://prometheus.io/download/), in Windows we can directly download the executable. Once downloaded we can simply run the executable.

```
$ prometheus.exe

level=info ts=2018-12-05T20:05:05.2715528Z caller=main.go:244 msg="Starting Prometheus" version="(version=2.5.0, branch=HEAD, revision=67dc912ac8b24f94a1fc478f352d25179c94ab9b)"
level=info ts=2018-12-05T20:05:05.2725529Z caller=main.go:245 build_context="(go=go1.11.1, user=root@578ab108d0b9, date=20181106-11:50:04)"
level=info ts=2018-12-05T20:05:05.2725529Z caller=main.go:246 host_details=(windows)
level=info ts=2018-12-05T20:05:05.2735525Z caller=main.go:247 fd_limits=N/A
level=info ts=2018-12-05T20:05:05.2735525Z caller=main.go:248 vm_limits=N/A
level=info ts=2018-12-05T20:05:05.2745512Z caller=main.go:562 msg="Starting TSDB ..."
level=info ts=2018-12-05T20:05:05.2745512Z caller=web.go:399 component=web msg="Start listening for connections" address=0.0.0.0:9090
```

Prometheus is now running properly and we should be able to access the UI from `localhost:9090`. For the moment the only metrics available are the metrics from the Prometheus instance itself. The way Prometheus gets metrics is via scrapping. It will scrap endpoints which are configured in the `prometheus.yml` at an interval specified and store those metrics. If we look into the files extracted, we should also have the `prometheus.yml` configuration with it.  Because we will be monitoring metrics from our ASP NET Core application, we need to add it under the `scrape_configs`:

```
scrape_configs:
  - job_name: api
    metrics_path: /metrics
    static_configs:
    - targets: ['localhost:5000']
```

We added a job named `api` and specified the target being `localhost:5000/metrics`. Next we simply restart Prometheus and it will pick up the configuration and start scrapping `localhost:5000/metrics` for metrics every 15 seconds (default interval setup).

## 2. Push metrics from ASP NET Core

```
public class MonitorAttribute : Attribute { }
```

```
public interface IMonitoringService
{
    bool Monitor(string httpMethod, PathString path);
}
```

```
public class MonitoringService: IMonitoringService
{
    private (string httpMethod, TemplateMatcher matcher)[] _matchers;

    public MonitoringService(IApiDescriptionGroupCollectionProvider provider)
    {
        _matchers =
            provider
                .ApiDescriptionGroups
                .Items
                .SelectMany(group => group.Items)
                .Where(x =>
                    x.ActionDescriptor is ControllerActionDescriptor
                    && ((ControllerActionDescriptor)x.ActionDescriptor).MethodInfo.CustomAttributes.Any(attr => attr.AttributeType == typeof(MonitorAttribute)))
                .Select(desc => {
                    var routeTemplate = TemplateParser.Parse(desc.RelativePath);
                    var routeValues = new RouteValueDictionary (routeTemplate
                        .Parameters
                        .ToDictionary(x => x.Name, y => y.DefaultValue));
                    var matcher = new TemplateMatcher(routeTemplate, routeValues);
                    return (desc.HttpMethod, matcher);
                })
                .ToArray();
    }

    public bool Monitor(string httpMethod, PathString path)
    {
        return _matchers.Any(m => m.httpMethod == httpMethod && m.matcher.TryMatch(path, new RouteValueDictionary()));
    }
}
```

```
public static class MonitoringExtensions
{
    public static IServiceCollection AddMonitoring(this IServiceCollection services)
    {
        return services.AddSingleton<IMonitoringService, MonitoringService>();
    }

    public static IApplicationBuilder UseMonitoring(this IApplicationBuilder builder)
    {
        return builder
            .UseMetricServer()
            .UseMiddleware<ResponseTimeMiddleware>()
            .UseMiddleware<StatusCodeMiddleware>();
    }
}
```

```
public class ResponseTimeMiddleware
{
    private readonly RequestDelegate _next;

    public ResponseTimeMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, IMonitoringService service, ICollectorRegistry registry)
    {
        if (service.Monitor(context.Request.Method, context.Request.Path))
        {
            var sw = Stopwatch.StartNew();
            await _next(context);
            sw.Stop();

            var histogram =
                Metrics
                    .WithCustomRegistry(registry)
                    .CreateHistogram(
                        "api_response_time_seconds",
                        "API Response Time in seconds",
                        null,
                        "method",
                        "path");

            histogram
                .WithLabels(context.Request.Method, context.Request.Path)
                .Observe(sw.Elapsed.TotalSeconds);
        }
        else
        {
            await _next(context);
        }
    }
}
```

```
[Monitor]
[HttpGet]
public ActionResult<string> Get()
{
    return "Hello";
}
```

```
public void ConfigureServices(IServiceCollection services)
{
  services.AddMonitoring();
}

public void Configure(IApplicationBuilder app, IHostingEnvironment env)
{
  app.UseMonitoring();
}
```