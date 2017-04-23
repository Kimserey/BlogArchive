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

```
[HttpGet]
[HelloFilter]
public string Get1()
{
    return "works";
}
```

## 2. Implement `IActionFilter`

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

## 3. Use `ServiceFilterAttribute`

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

```        
[HttpGet("3")]
[ServiceFilter(typeof(Hello3Filter))]
public string Get3()
{
    return "works";
}
```

## 4. Use `TypeFilterAttribute`

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

```
[HttpGet("4")]
[TypeFilter(typeof(Hello4Filter), Arguments = new[] { "some argument" })]
public string Get4()
{
    return "works";
}
```

## 5. Implement `IFilterFactor`

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

    private class Hello5FilterImpl : ActionFilterAttribute
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
}
```

```
[HttpGet("5")]
[Hello5Filter("some argument")]
public string Get5()
{
    return "works";
}
```

# Conclusion