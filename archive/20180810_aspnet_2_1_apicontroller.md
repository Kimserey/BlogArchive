# ApiController attribute in ASP NET Core 2.1 

ASP NET Core 2.1 brings a set a enhacements for Web API development, Web API being a service accessible via HTTP and returning result in Json format. Those enhancements aim to simplify the composition of those APIs and also remove unecessary functionalities. Today we will explore those enhancements in five parts

1. `ControllerBase`and `ApiController`
2. Automatic model validation
3. Inferred model binding
4. `ActionResult<T>`

## 1. ControllerBase and ApiController

Prior everything, we should set the compatibility version of ASP NET Core by using the `.SetCompatibilityVersion`.

```c#
services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_1);
```

In the past, we used to inherit from `Controller` which was providing functions to return different HTTP status code results together with optional data like `Ok(...)` or `Json(...)`, but it was also used to display Razor views like `View(...)` or `PartialView(...)`. 

Starting from 2.1, it is now recommended to inherit from `ControllerBase` instead. `Controller` still exists and can be used for Razor/static website work but inheriting from `ControllerBase` just gives us the necessary functions to write a Web API.

And to enable the following features, we would need to decorate our controller with the `[ApiController]` attribute and specifying the route is mandatory.

```c#
[Route("api/[controller]")]
[ApiController]
public class MyController: ControllerBase
{ }
```

## 2. Automatic model validation

When we had annotation on arguments, we used to have to validate the argument by calling `ModelState.IsValid` or by using a filter which would validate the model state prior reaching the controller. This is no longer needed.

```c#
public class MyModel
{
    [Required]
    public string Name { get; set; }
}
```

```c#
[HttpPost]
public async Task<IActionResult> Post([FromBody]MyModel viewModel)
{
    // This is no longer required
    // if (!ModelState.IsValid)
    // {
    //     return BadRequest();
    // }

    Console.WriteLine(viewModel.Name);
    
    return Ok();
}
```

The model state will be validated by default and `400` will be returned with the validation messages as response body.

## 3. Inferred model binding

Taking the same example as 2), model binding is also now inferred with the following:

| Attribute | Position | Inference |
| - | - | - |
| [FromBody] | Request body | Inferred for complex type parameters |
| [FromForm] | Form data in the request body |  Inferred for action parameters of type IFormFile and IFormFileCollection |
| [FromQuery] | Request query string parameter | Inferred for any other action parameters |
| [FromRoute] | Route data from the current request | Inferred for any action parameter name matching a parameter in the route template |
| [FromServices] | The request service injected as an action parameter | Not inferred |
| [FromHeader] | Request header | Not inferred |

So from the previous example, we would no longer need to specify that the argument come from the body of the request.

```c#
[HttpPost]
public IActionResult Post(MyModel viewModel)
{
    Console.WriteLine(viewModel.Name);
    
    return Ok();
}
```

**`IEnumerable<IFormFile>` is not inferred, to be able to get the files in a controller, we must use `IFormFileCollection` instead.**

## 4. `ActionResult<T>`

Lastly to provide Swagger the type to display provide the model in the Swagger UI, we needed to add the `[ProducesResponseType(typeof(MyModel), 200)]` attribute.

```c#
[HttpPost]
[ProducesResponseType(typeof(MyModel), 200)]
public IActionResult Post(MyModel viewModel)
{
    Console.WriteLine(viewModel.Name);
    
    return Ok(viewModel);
}
```

This way, Swagger would be able to deduce the Json format of `MyModel`. But the problem with that is that there was no direct link between the actual response and the attribute type specified.

A common problem was when mistakes were made where the attribute would specify a single type but the return was actually and array of that type like so:

```c#
[HttpPost]
[ProducesResponseType(typeof(MyModel), 200)]
public IActionResult Post(MyModel viewModel)
{
    Console.WriteLine(viewModel.Name);
    
    return Ok(new List<MyModel> { viewModel });
}
```

Nothing would prevent this but the type returned is a list of `MyModel` while the specified produce response type is `MyModel`.
The other problem is the `IActionResult` not enforcing the type of the returned result. This turned to be problematic as all functions like `Ok(...)` or `Json(...)` would take an `object` as argument.

To bring back type safety, 2.1 comes with `ActionResult<T>`. This solves the two precedent problems as it is used by Swagger to deduce the type and contains implicit casts which allows us to directly return the object themselves without passing by any base function.

```c#
[HttpPost]
[ProducesResponseType(200)]
public ActionResult<MyModel> Post(MyModel viewModel)
{
    Console.WriteLine(viewModel.Name);
    
    return viewModel;
}
```

We now have trimmed down by quite a bit the code if we compare both.

Before:

```c#
[HttpPost]
[ProducesResponseType(typeof(MyModel), 200)]
public IActionResult Post([FromBody]MyModel viewModel)
{
    if (!ModelState.IsValid)
    {
         return BadRequest();
    }

    Console.WriteLine(viewModel.Name);
    
    return Ok(viewModel);
}
```

After:

```c#
[HttpPost]
[ProducesResponseType(200)]
public ActionResult<MyModel> Post(MyModel viewModel)
{
    Console.WriteLine(viewModel.Name);
    
    return viewModel;
}
```

And that concludes today's post!

## Conclusion

Today we saw the functionalities added in ASP.NET Core 2.1 for Web API development. We saw the automatic model validation, allowing us to not have to care much and assume that the model would be valid once it reach the controller endpoint. Then we saw the binding inference which would detect by convention where would the arguments be coming from. And lastly we saw how the new `ActionResult<T>` type helped in simplifying our code while bringing type safety. Hope you like this post, see you next time! 