# ASP NET Core HttpClient resilience

```
Microsoft.Extensions.Http.Polly
```

```
public static class PolicyHandler
{
    /// <summary>
    /// Handle 5.x.x, 408 timeout, 404 not found and timeout rejection from client and retry for the retry count specified.
    /// </summary>
    public static IAsyncPolicy<HttpResponseMessage> WaitAndRetry(Func<int, TimeSpan> sleepDurationProvider, Action<DelegateResult<HttpResponseMessage>, TimeSpan> onFailure, int retryCount = 5) =>
        HttpPolicyExtensions
            .HandleTransientHttpError()
            .OrResult(msg => msg.StatusCode == HttpStatusCode.NotFound)
            .Or<TimeoutRejectedException>()
            .WaitAndRetryAsync(retryCount, sleepDurationProvider, onFailure);

    /// <summary>
    /// Handle 5.x.x, 408 timeout, 404 not found and timeout rejection from client and retry 5 times while sleeping in an exponential manner.
    /// </summary>
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

```
public static class HttpClientBuilderExtensions
{
    public static IHttpClientBuilder AddPolicyHandlers(this IHttpClientBuilder builder, IAsyncPolicy<HttpResponseMessage>[] policies)
    {
        foreach (var policy in policies)
        {
            builder.AddPolicyHandler(policy);
        }
        return builder;
    }
}
```

```
public void ConfigureServices(IServiceCollection services)
{
    services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_1);

    services
        .AddHttpClient<IHealthCheckService, HealthCheckService>()
        .AddPolicyHandler(PolicyHandler.WaitAndRetry())
        .AddPolicyHandler(PolicyHandler.Timeout());
}
```