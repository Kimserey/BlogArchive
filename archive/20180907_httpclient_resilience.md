# Implement timeout and retry policies for HttpClient in ASP NET Core

Few weeks ago I explained [how to use the new `HttpClientFactory`])(https://kimsereyblog.blogspot.com/2018/07/httpclientfactory-in-asp-net-core-21.html). This freed ourselves from managing the confusing lifecycle of a HttpClient and at the same time allowed us to setup commmon options like base address for all HttpClient injections in our classes. Today we will see how we can setup timeout and retry policies for the HttpClient in in ASP NET Core using [Polly](https://github.com/App-vNext/Polly).

1. Setup a simple service using HttpClient
2. Install Polly extensions for ASP NET Core
3. Setup Polly policies

## 1. Setup a simple service using HttpClient

In [the previous blog post](https://kimsereyblog.blogspot.com/2018/07/httpclientfactory-in-asp-net-core-21.html) we saw how we could setup a `HttpClient` and register it to the service collection.

Here is a simple service client which will be injected throughout the application:

```
public interface IMyApiClient
{
    Task<HttpResponseMessage> Get();
}
```

And here is the implementation:

```
public class MyApiClient : IMyApiClient
{
    private readonly HttpClient _client;

    public ApiClient(HttpClient client)
    {
        _client = client;
    }

    public Task<HttpResponseMessage> Get()
    {
        return _client.GetAsync();
    }
}
```

We can then register it to the service collection:

```
public void ConfigureServices(IServiceCollection services)
{
    services
        .AddHttpClient<IMyApiClient, MyApiClient>(opts =>
        {
            opts.BaseAddress = new Uri("http://localhost:5100");
        });
}
```

We are now able to inject `IMyApiClient` in our services or controllers, and once we call `.Get()`, we will be hitting `GET http://localhost:5100` using a `HttpClient` managed by the framework. Now apart from the lifecycle management, another major benefits from the abstraction is the ability to make the client more resilient by introduce [Polly](https://github.com/App-vNext/Polly).

## 2. Install Polly extensions for ASP NET Core

Polly can be installed together with the ASP NET Core extensions by installing the following package:

```
Microsoft.Extensions.Http.Polly
```

The extensions library provides a set of extensions on the `IHttpClientBuilder` like the following: 

```
public static IHttpClientBuilder AddPolicyHandler(this IHttpClientBuilder builder, IAsyncPolicy<HttpResponseMessage> policy);
```

Which can be used to like so:

```
services
    .AddHttpClient<IApiClient, ApiClient>(opts =>
    {
        opts.BaseAddress = new Uri("http://localhost:5100");
    })
    .AddPolicyHandler(MyPolicy);
```

`IAsyncPolicy<T>` is the policy class provided by Polly which we will need to build.

## 3. Setup Polly policies

In the case of a `HttpClient`, the common policies are the __retry__ policy and the __timeout__ policy.
Here is an example of a `WaitAndRetry` policy.

```
HttpPolicyExtensions
    .HandleTransientHttpError()
    .OrResult(msg => msg.StatusCode == HttpStatusCode.NotFound)
    .Or<TimeoutRejectedException>()
    .WaitAndRetryAsync(5, retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)));
```

`HttpPolicyExtensions.HandleTransientHttpError()` returns a `PolicyBuilder<HttpResponseMessage>` provided by the `Polly.Extensions.Http` library. It setups a policy builder which handles `5.x.x` and `408` error responses.
We then add other type of messages to handle by using `OrResult(T -> bool)` where we add handling of `404` error responses. And lastly, we also handle timeout exceptions by using `Or<Ttype>` passing in the `TimeoutRejectedException` from `Polly`. Once the conditions are setup, we can apply the policy `WaitAndRetryAsync` where we retry for five times and wait in an exponential manner between each retry.

Timeout is easier as we only need to wait to a certain timespan:

```
Policy.TimeoutAsync<HttpResponseMessage>(TimeSpan.FromSeconds(5));
```

And we are done implementing the two policies:

```
public static class PolicyHandler
{
    public static IAsyncPolicy<HttpResponseMessage> WaitAndRetry(int retryCount = 5) =>
        HttpPolicyExtensions
            .HandleTransientHttpError()
            .OrResult(msg => msg.StatusCode == HttpStatusCode.NotFound)
            .Or<TimeoutRejectedException>()
            .WaitAndRetryAsync(retryCount, retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)));

    public static IAsyncPolicy<HttpResponseMessage> Timeout(int seconds = 2) =>
        Policy.TimeoutAsync<HttpResponseMessage>(TimeSpan.FromSeconds(seconds));
}
```

We can now simply add them using the `.AddPolicyHanlder` extension.

```
public void ConfigureServices(IServiceCollection services)
{
    services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_1);

    services
        .AddHttpClient<IApiClient, ApiClient>(opts =>
        {
            opts.BaseAddress = new Uri("http://localhost:5100");
        })
        .AddPolicyHandler(PolicyHandler.WaitAndRetry())
        .AddPolicyHandler(PolicyHandler.Timeout());
}
```

And this concludes today's post, all calls from `IMyApiClient.Get()` will now be subject to the timeout and retry policies!

## Conclusion

Today we saw how to implement timeout and retry policies for `HttpClient` in ASP NET Core using `Polly`. We started by defining a HttpClient service which would be used throughout our application. Next we moved on to install the Polly extensions for ASP NET Core and finished by implementing the timeout and retry policies. Hope you like this post, see you next time!