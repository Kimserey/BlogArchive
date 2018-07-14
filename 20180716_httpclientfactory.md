# HttpClientFactory in ASP NET Core 2.1

ASP.NET Core 2.1 ships with a factory for `HttpClient` called `HttpclientFactory`. This factory allows us to no longer care about the lifecycle of the `HttpClient` by leaving it to the framework. Today we will see two ways of instantiating clients:

 1. Typed clients
 2. Named clients

## 1. Typed clients

To use the factory, we start first by registering it to the service collection with `.AddHttpClient()` which is an extension coming from `Microsoft.Extensions.Http`.

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

The extensions takes an action as parameter allowing us to specify a base address. Make sure to only specify the root address as any URI will be discarded. As we can see here, we need to specify a type which is our own client, `MyTypedClient`, who will receive an `HttpClient` configured by the `Action` argument in `AddHttpClient<T>(...)`.

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

Here we simply create one function to handle a post of data and use the `HttpClient` with `PostAsJsonAsync` to post the value. Next from our controller endpoint, we can inject our own client `MyTypedClient` and use it.

```c#
[HttpPost]
public async Task<ActionResult<string>> Post([FromServices]MyTypedClient client, [FromBody] Dto value)
{
    return await client.Post(value);
}
```

## 2. Named clients

The second way to get a `HttpClient` is to use named clients. Instead of passing a type, we use the overload specifying a name for the client:

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

Next in the controller, we inject the `IHttpClientFactory` which allows us to instantiate a client using the `CreateClient` factory function by specifying the name of the configuration we want to use.

```c#
[HttpPost]
public async Task<ActionResult<string>> Post([FromServices]IHttpClientFactory factory, [FromBody] Dto value)
{
    var result = await factory.CreateClient("my-named-client").PostAsJsonAsync("api/values", value);
    return await result.Content.ReadAsStringAsync();
}
```

And that concludes today's post on how to use the new `HttpClientFactory`, see you next time!