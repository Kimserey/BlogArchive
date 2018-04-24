# Healthchecks in ASP NET Core

Healthchecks are used to assess the health of an application. There are multiple level of checks which can be implemented, the first level being whether the application is itself running. The second level being whether the application dependencies, services, databases, files, are accessible by the application. Last level being whether the process itself is healthy, consume a reasonable amount of CPU/RAM.
Today we will see how we can implement a simple healthcheck middleware for ASP NET Core in three parts:

1. Objective
2. Build the framework
3. Sqlite Healthcheck extension

## 1. Objective

_ASP NET Core is cooking a healthcheck framework but the nuget package hasn't been created yet therefore only the codebase is available. The framework in this post is a simpler version inspired by the official healthcheck framework._

We will be creating a framework allowing us to register comprehensive healthchecks.

```c#
public void ConfigureServices(IServiceCollection services)
{
    // ... rest of function

    services.AddHealthChecks(c =>
    {
        c.AddSelfCheck("Web is running.");
        c.AddSqliteCheck(
            Configuration["connectionStrings:database"],
            "TableA",
            "TableB");
    });
}


public void Configure(IApplicationBuilder app, IHostingEnvironment env)
{
    // ... rest of function

    app.UseHealthChecks();

    // ... rest of function
}
```

Here we register a self healthcheck and a Sqlite healthcheck verifying the existence of tables.

When we hit the `/health` endpoint we will get the following message:

```c#
{
  "results": [
    {
      "name": "SelfCheck",
      "status": "Healthy",
      "message": "Web is running."
    },
    {
      "name": "SqliteCheck",
      "status": "Healthy",
      "message": "Successfully found all table(s) on Sqlite database '..\\Data\\database.db'. Tables: TableA, TableB"
    }
  ],
  "compositeStatus": "Healthy"
}
```

In order to do this, we will start by implementing the framework.

## 2. Build the framework

### 2.1 Abstractions

To achieve the usage describe in 1) we will be implementing three interfaces.

`IHealthCheck`, this is the main healthcheck interface for the implementation of each concrete healthcheck.

```c#
public interface IHealthCheck
{
    Task<HealthCheckResult> Check();
}
```

`IHealthCheckService`, this is the main entrypoint to trigger all healthchecks and return a composite result.

```c#
public interface IHealthCheckService
{
    Task<CompositeHealthCheckResult> CheckAll();
}
```

Next we create an abstraction of a builder which is used to register all healthchecks via a simple API.

```c#
public interface IHealthCheckBuilder
{
    IHealthCheckBuilder Add(Func<IServiceProvider, IHealthCheck> factory);

    IEnumerable<Func<IServiceProvider, IHealthCheck>> GetAll();
}
```

The `Add` takes a factory allowing to build the healthcheck as we want to be able to healthcheck the injection of the healthcheck dependencies so instantiating the healthcheck object can be part of the check.

### 2.2 Implementations

Now we can implement the interfaces starting from the healthcheck.

``` c#
public enum CheckStatus
{
    Healthy,
    Unhealthy
}

public class HealthCheckResult
{
    public string Name { get; set; }

    public CheckStatus Status { get; set; }

    public string Message { get; set; }
}

public class SelfCheck : IHealthCheck
{
    private string _name;
    private string _message;

    public SelfCheck(string message)
    {
        _name = typeof(SelfCheck).Name;
        _message = message;
    }

    public Task<HealthCheckResult> Check()
    {
        return Task.FromResult(new HealthCheckResult
        {
            Name = _name,
            Message = _message,
            Status = CheckStatus.Healthy
        });
    }
}
```

Next we implement the service which runs all healthchecks and construct the composite result.

```c#
public class CompositeHealthCheckResult
{
    public IEnumerable<HealthCheckResult> Results { get; set; }

    public CheckStatus CompositeStatus => Results.Any(r => r.Status == CheckStatus.Unhealthy) ? CheckStatus.Unhealthy : CheckStatus.Healthy;
}

public class HealthCheckService : IHealthCheckService
{
    private IEnumerable<IHealthCheck> _checks;

    public HealthCheckService(IEnumerable<IHealthCheck> checks)
    {
        _checks = checks;
    }

    public async Task<CompositeHealthCheckResult> CheckAll()
    {
        return new CompositeHealthCheckResult
        {
            Results = await Task.WhenAll(_checks.Select(async c => await c.Check()))
        };
    }
}
```

As we can see, the service expects the healthchecks to be registered in the DI. To configure that we provide the Healthcheck builder.

```c#
public class HealthCheckBuilder : IHealthCheckBuilder
{
    private List<Func<IServiceProvider, IHealthCheck>> _factories = new List<Func<IServiceProvider, IHealthCheck>>();

    public IHealthCheckBuilder Add(Func<IServiceProvider, IHealthCheck> factory)
    {
        _factories.Add(factory);
        return this;
    }

    public IEnumerable<Func<IServiceProvider, IHealthCheck>> GetAll()
    {
        return _factories;
    }
}
```

The builder allows us to register the healthchecks with a simple API `.AddHealthcheck`.
To make things even more explicit, we can create an extension on the `IHealthcheckBuilder`.

```c#
public static class HealthCheckBuilderExtensions
{
    public static IHealthCheckBuilder AddSelfCheck(this IHealthCheckBuilder builder, string message) =>
        builder.Add(sp => new SelfCheck(message));
}
```

It becomes now more explicit at registration.

```c#
services.AddHealthChecks(c =>
{
    c.AddSelfCheck("Web is running.");
});
```

### 2.3 Middleware

We could use the service as it is and inject it in a MVC controller but since it isn't really part of the business logic, it is good to provide it as a Middleware.

To do that we create a Middleware which handle `/health`.

```c#
public class HealthCheckMiddleware
{
    private RequestDelegate _next;

    public HealthCheckMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task Invoke(HttpContext context, IHealthCheckService healthCheckService)
    {
        if (context.Request.Path.Equals("/health") && context.Request.Method == HttpMethods.Get)
        {
            var result = await healthCheckService.CheckAll();

            if (result.CompositeStatus != CheckStatus.Healthy)
                context.Response.StatusCode = 503;

            context.Response.Headers.Add("content-type", "application/json");
            await context.Response.WriteAsync(
                JsonConvert.SerializeObject(
                    result,
                    new JsonSerializerSettings {
                        Converters = { new StringEnumConverter() },
                        ContractResolver = new CamelCasePropertyNamesContractResolver()
                    }
                )
            );
            return;
        }

        await _next(context);
    }
}
```

We then create an extension on the application builder to handle the healthcheck endpoint at the beginning of the pipeline.

```c#
public static class ApplicationBuilderExtensions
{
    public static IApplicationBuilder UseHealthChecks(this IApplicationBuilder app) =>
        app.UseMiddleware<HealthCheckMiddleware>();
}
```

And we can then use it in `Startup.cs`.

```c#
app.UseHealthChecks();
```

We now have a fully functional healthcheck library.

## 3. Sqlite Healthcheck extension

We saw how we could extend the healthcheck library by adding an extension method on the healthcheck builder.
This should be the default way of extending the framework.

If we were to add a Sqlite healthcheck, we would start by defining the healthcheck:

```c#
public class SqliteCheck : IHealthCheck
{
    private string _name;
    private string _connectionString;
    private string[] _tables;

    public SqliteCheck(string connectionString, string[] tables)
    {
        _name = typeof(SqliteCheck).Name;
        _connectionString = connectionString;
        _tables = tables;
    }

    public Task<HealthCheckResult> Check()
    {
        try
        {
            var path = _connectionString.Remove(0, "Date Source=".Length);

            if (File.Exists(path))
            {
                using (var conn = new SQLiteConnection(path))
                {
                    var count = _tables.Aggregate(0, (res, t) => res + conn.CreateCommand($"SELECT COUNT(name) FROM sqlite_master WHERE type='table' AND name='{t}'").ExecuteScalar<int>());
                    if (count == _tables.Length)
                    {
                        return Task.FromResult(new HealthCheckResult
                        {
                            Name = _name,
                            Status = CheckStatus.Healthy,
                            Message = $"Successfully found all table(s) on Sqlite database '{path}'. Tables: {string.Join(", ", _tables)}"
                        });
                    }
                    else
                    {
                        return Task.FromResult(new HealthCheckResult
                        {
                            Name = _name,
                            Status = CheckStatus.Unhealthy,
                            Message = $"Failed to find all tables on Sqlite database '{path}'. Tables: {string.Join(", ", _tables)}"
                        });
                    }
                }
            }
            else
            {
                return Task.FromResult(new HealthCheckResult
                {
                    Name = _name,
                    Status = CheckStatus.Unhealthy,
                    Message = $"Failed to find Sqlite database at '{path}'."
                });
            }

        }
        catch (Exception ex)
        {
            return Task.FromResult(new HealthCheckResult
            {
                Name = _name,
                Status = CheckStatus.Unhealthy,
                Message = "Failed to execute command 'PRAGMA table_info(tabe-name)' on database. Message: " + ex.Message
            });
        }
    }
}
```

And create an extension registering the healthcheck:

```c#
public static IHealthCheckBuilder AddSqliteCheck(this IHealthCheckBuilder builder, string connectionString, params string[] tables) =>
    builder.Add(sp => new SqliteCheck(connectionString, tables));
```

We can then add it in our DI:

```c#
services.AddHealthChecks(c =>
{
    c.AddSelfCheck("Web is running.");
    c.AddSqliteCheck(
        Configuration["connectionStrings:database"],
        "TableA",
        "TableB");
});
```

And that concludes our healthcheck library.

# Conclusion
