# HttpClientFactory in ASP NET Core 2.1

ASP.NET Core 2.1 ships with a factory for `HttpClient` called `HttpclientFactory`. This factory allows us to no longer care about the lifecycle of the `HttpClient` by leaving it to the framework. Today we will see two ways of instantiating clients:

 1. Typed clients
 2. Named clients

## 1. Typed clients

```c#
public void ConfigureServices(IServiceCollection services)
{
    services.AddMvc();

    services.AddHttpClient<MyTypeClient>(client =>
    {
        client.BaseAddress = new Uri("http://localhost:5100");
    });
}
```

```c#
public class MyTypedClient
{
    private HttpClient _client;

    public MyTypedClient(HttpClient client)
    {
        _client = client;
    }

    public async Task<string> Post(Dto value)
    {
        var result = await _client.PostAsJsonAsync("api/values", value);
        return await result.Content.ReadAsStringAsync();
    }
}
```

```c#
[HttpPost]
public async Task<ActionResult<string>> Post([FromServices]MyTypedClient client, [FromBody] Dto value)
{
    return await client.Post(value);
}
```

## 2. Named clients

```c#
public void ConfigureServices(IServiceCollection services)
{
    services.AddMvc();

    services.AddHttpClient("my-named-client", client =>
    {
        client.BaseAddress = new Uri("http://localhost:5100");
    });
}
```

```c#
[HttpPost]
public async Task<ActionResult<string>> Post([FromServices]IHttpClientFactory factory, [FromBody] Dto value)
{
    var result = await factory.CreateClient("named-client").PostAsJsonAsync("api/values", value);
    return await result.Content.ReadAsStringAsync();
}
```

And that concludes today's post on how to use the new `HttpClientFactory`, see you next time!