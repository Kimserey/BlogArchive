# Attribute route in ASP NET Core

Attribute route in ASP NET Core is an easy way to define URL routes for Web API projects. Even though it looks straight forward, there can be instance where it gets confusing because of all the options provided. Today we will see the meaning of the different options and how they affect the constructed route. This post will be composed by 3 parts:

```
1. Route attribute
2. Route values and token replacement
3. "/" or ""
```

## 1. Route attribute

The route attribute can be set on the controller or on an action or both.
It is used to overwride the convention route.

Take not of the following statement:
_With attribute routing the controller name and action names play no role in which action is selected._
[https://docs.microsoft.com/en-us/aspnet/core/mvc/controllers/routing](https://docs.microsoft.com/en-us/aspnet/core/mvc/controllers/routing)

So for example specifying the following:

```
Route("values")
public class ValuesController: Controler 
{
    Route("list")
    public IActionResult List()
    {
        return Ok();
    }
}
```

Will match `[GET] /values/list`.

Attribute route can also be used with Http verb attributes.
```
[HttpGet("list")]
[HttpPost("list")]
[HttpPut("list")]
[HttpPatch("list")]
[HttpDelete("list")]
```

## 2. Route values and token replacement

The route can accept values specified in braces {...} and can also accept token replacement in brackets [...].

Braces are used to extract values in the controller parameter. A common scenario is parsing an identifier.

HttpGet("values/{id}")

Brackets are token replacement like controller or action.
[controller] will be replaced by the controller name.
[action] will be replaced by the action name.

## 3. "/" or ""

Depending on where the attribute is placed, the construction of the route is different.

Placing the route on the controller will prepend all route on actions apart from the routes starting with "/".

I have compiled a list of examples together with the corresponding route:

By default the routes are added together. Prepending the route with a slash prevents the adding of the route which results in the disgard of the controller route.

Here is the code in ASP NET MVC doing the override:

```
private static string CombineCore(string left, string right)
{
    if (left == null && right == null)
    {
        return null;
    }
    else if (right == null)
    {
        return left;
    }
    else if (IsEmptyLeftSegment(left) || IsOverridePattern(right))
    {
        return right;
    }

    if (left.EndsWith("/", StringComparison.Ordinal))
    {
        return left + right;
    }

    // Both templates contain some text.
    return left + "/" + right;
}

private static bool IsEmptyLeftSegment(string template)
{
    return template == null ||
        template.Equals(string.Empty, StringComparison.Ordinal) ||
        template.Equals("~/", StringComparison.Ordinal) ||
        template.Equals("/", StringComparison.Ordinal);
}
```

# Conclusion

Today we saw how to define routes used attribute route. It is very easy to setup explicit routes. I hope this post removed some of the confusion which can occur with the slash or empty string route. If you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](). See you next time!