# Filters in ASP NET Core - what are they and how to use them

ASP NET Core comes with a concept of filters. Filters intercept the stages of the MVC pipeline and allows us to run code before/after their executions. They are meant to be used for cross-cutting concerns; logics which is required accross the whole application, generally not business oriented. One example is authorization where in a Web API, we would use to prevent unauthorized request to execute the code in our controllers. In order to do that we would have a filter at the entrance of the pipeline. In fact, ASP NET Core has predefine stages, the diagram can be found on the documentation [https://docs.microsoft.com/en-us/aspnet/core/mvc/controllers/filters](https://docs.microsoft.com/en-us/aspnet/core/mvc/controllers/filters). Another example of a cross-cutting concern would be for logging and timing functions. While the concept of filters is easy to understand, the way to implement those aren't always straight forward, especially when the filter instantiation itself requires simple objects. In order to illustrate our example we will only filter the `Action` stage. The same implementations can be applied to any stages of MVC pipeline.

Today I will explain the different ways to create filters. This post will be composed by 5 parts:

 1. Simple action filter with `ActionFilterAttribute` base
 2. Implement `IActionFilter`
 3. Use `ServiceFilterAttribute`
 4. Use `TypeFilterAttribute`
 5. Implement `IFilterFactor`

The full source code is available on my github [https://github.com/Kimserey/authorization-samples/blob/master/AuthorizationSamples.FiltersTest/Filters.cs](https://github.com/Kimserey/authorization-samples/blob/master/AuthorizationSamples.FiltersTest/Filters.cs).

## 1. Simple action filter with `ActionFilterAttribute` base

ASP NET Core comes with default empty implementation of the filter iterfaces. One of those is ActionFilterAttribute which implements IActionFilter and inherit from Attribute.
We can use it to easily add filter logic before and after the action is invoked:

```
public class HelloFilterAttribute: ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext context)
    {
        Console.WriteLine("Hello");
        base.OnActionExecuting(context);
    }

    public override void OnActionExecuted(ActionExecutedContext context)
    {
        base.OnActionExecuted(context);
        Console.WriteLine("Bye bye");
    }
}
```

Since ActionFilterAttribute is an attribute, we can decorate our action and the filter will be applied:

```
[HttpGet]
[HelloFilter]
public string Get1()
{
    return "works";
}
```

Note that there is a synchronous version and asynchronous. This attribute implements both but only one version should have an implementation.

## 2. Implement `IActionFilter`

We can also implement IActionFilter ourselves and use it.
The only difference as you can see is that if we only wish to implement before or after filter we will have the other function empty.

```
public class Hello2FilterAttribute : Attribute, IActionFilter
{
    public void OnActionExecuted(ActionExecutedContext context)
    {
        Console.WriteLine("Hello");
    }

    public void OnActionExecuting(ActionExecutingContext context)
    { }
}
```

```
[HttpGet("2")]
[Hello2Filter]
public string Get2()
{
    return "works";
}
```

When we do not need arguments for our filters to function, 1 or 2 are enough. But when we need to have services given from dependency injection, `ServiceFilter` can be used.

## 3. Use `ServiceFilterAttribute`

Let's add a service which we register on the service provider.

```
public interface IHelloService
{
    string SayHello();
}

public class HelloService : IHelloService
{
    public string SayHello()
    {
        return "Hello from injected service";
    }
}
```

And register it into the services:

```
services.AddTransient<IHelloService, HelloService>();
```

And we use the service within our filter:

```
public class Hello3Filter : IActionFilter
{
    private IHelloService _service;

    public Hello3Filter(IHelloService service)
    {
        _service = service;
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
        Console.WriteLine(_service.SayHello());
    }

    public void OnActionExecuting(ActionExecutingContext context)
    { }
}
```

Now if we need to use the service within the filter, we will need a way to resolve the filter using the service provider so that before that it will automatically resolve our service.
That's where service filter comes into picture. We can use the service filter directly on the action and pass the type of our filter implementation.

Since our filter is resolved from the service provider, we need to register it.

```
services.AddScoped<Hello3Filter>();
```

Lastly we can use the filter by giving its type to the `ServiceFilter`:

```        
[HttpGet("3")]
[ServiceFilter(typeof(Hello3Filter))]
public string Get3()
{
    return "works";
}
```

When the action is invoked the filter will have the proper service injected. The advantage of the service filter is that we can manage the life cycle scoped, transient or singleton depending on how we registered it in `Startup.cs`.

Now if we needed extra arguments to our filter, we can no longer resolve it via service filter.

## 4. Use `TypeFilterAttribute`

If the arguments needed fit into the attributes argument constrain, we can use `TypeFilter`.
For example, if our service needs an extra string argument which can't be resolved via DI:

```
public class Hello4Filter : IActionFilter
{
    private IHelloService _service;
    private string _extraText;

    public Hello4Filter(IHelloService service, string extraText)
    {
        _service = service;
        _extraText = extraText;
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
        Console.WriteLine($"{_service.SayHello()} | {_extraText}");
    }

    public void OnActionExecuting(ActionExecutingContext context)
    { }
}
```

We can use this filter like so:

```
[HttpGet("4")]
[TypeFilter(typeof(Hello4Filter), Arguments = new[] { "some argument" })]
public string Get4()
{
    return "works";
}
```

The difference with the service filter is that the type filter instiantes the filter using the type provided and the arguments as opposed to the service filter which gets the instance from the service provider.

Since arguments in the filter are restricted by the attribute arguments, we can't have typical class passed. ServiceFilter and TypeFilter are actually implementation of IFilterFactory. If we want to have full control on the instantiation, we can implement the factory ourselves.

## 5. Implement `IFilterFactor`

Let's add a class which will be required in our filter:

```
public class HelloOptions
{
    public string Text { get; set; }
}
```

```
public class Hello5FilterImpl : ActionFilterAttribute
{
    private HelloOptions _testWithObject;
    private string _extraText;
    private IHelloService _service;

    public Hello5FilterImpl(IHelloService service, string extraText, HelloOptions testWithObject)
    {
        _service = service;
        _extraText = extraText;
        _testWithObject = testWithObject;
    }

    public override void OnActionExecuted(ActionExecutedContext context)
    {
        Console.WriteLine($"{_service.SayHello()} | {_extraText} | {_testWithObject.Text}");
    }
}
```

We can then implement the factory like so:

```
public class Hello5FilterAttribute: Attribute, IFilterFactory
{
    private string _extraText;

    // Indicates if the filter created can be reused accross requests.
    public bool IsReusable => false;

    public Hello5FilterAttribute(string extraText)
    {
        _extraText = extraText;
    }

    public IFilterMetadata CreateInstance(IServiceProvider serviceProvider)
    {
        // GetRequiredService<>() is available in Microsoft.Extensions.DependencyInjection
        // GetRequiredService VS GetService is that Required will throw exception when service can't be found, while the other will return null.
        return new Hello5FilterImpl(
            serviceProvider.GetRequiredService<IHelloService>(),
            _extraText,
            new HelloOptions { Text = "text from options" });
    }
}
```

The factory also have a property `IsReusable` which indicates if the filter created by the factory can be reused accross requests. If set to false, it will be instantiated per request.
We can then use the factory like so:

```
[HttpGet("5")]
[Hello5Filter("some argument")]
public string Get5()
{
    return "works";
}
```

# Conclusion

Today we saw how we could use the different filter implementations available in ASP NET Core to provide cross cutting concern. Depending on your needs, you can choose between implementing a simple filter or using service filter or type filter. Lastly if your requirements are more advanced, implementing yourself the filter factory will allow you to have full control. Hope you enjoyed this post as much as I enjoyed writing it! If you have any question leave it here or hit me on Twitter [@Kimserey_Lam](). See you next time!