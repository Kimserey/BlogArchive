# Attribute route in ASP NET Core

Attribute route in ASP NET Core is an easy way to define URL routes for Web API projects. There can be instance where it gets confusing because of all the options provided. Today we will see the meaning of the different options and how they affect the constructed route. This post will be composed by 3 parts:

```
1. Route attribute
2. Route values and token replacement
3. "/" or ""
```

## 1. Route attribute

There are two ways to define routing, convention and attribute. When both are set, attribute route takes priority over convention route. In this post we will only discuss attribute route.

Attribute route is specified using the `[Route(...)]` attribute. The route attribute can be set on controllers and actions. Setting the attribute on a controller will prefix all action route by the controller route.

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

Attribute route can also be used with http verb attributes:
```
[HttpGet("list")]
[HttpPost("list")]
[HttpPut("list")]
[HttpPatch("list")]
[HttpDelete("list")]
```

And specifying a route plus a http verb attributes have the same outcome:

```
[HttpGet("list")]
```

Is similar to:

```
[HttpGet]
[Route("list")]
```

## 2. Route values and token replacement

Routes can accept values specified in braces `{...}` and token replacement in brackets `[...]`.

Braces are used to extract values in the controller parameter. A common scenario is parsing an identifier.

```
[HttpGet("values/{id}")]
public IActionResult GetValue(string id)
```

Brackets are used for token replacement:
[controller] will be replaced by the controller name.
[action] will be replaced by the action name.

```
[Route(v1/[controller])]
public class ValuesController: Controller { }
```

`v1/[controller]` will replace `[controller]` by `Values`. It takes the name of the controller and remove the `Controller` postfix. If there isn't a `Controller` postfix it uses the full name.

`[action]` will be replaced by the action name.

```
public class ValuesController: Controller
{
    [Route([controller]/[action]/{id})]
    public IActionResult GetValue(string id)
    {
        return Ok();
    }
}
```

`[controller]/[action]/{id}` will be changed to `values/getvalue/{id}` where `id` can be any string.

## 3. "/" or ""

Controller route and action route added together by default. Prepending the action route with "/" (slash) prevents the addition of the controller route.

I have compiled a list of examples together with the corresponding routes [here](https://gist.github.com/Kimserey/44dba9557d48099bae9d05f37cd6c10f).

To understand better what happens, here is the code in ASP NET MVC doing the override:

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

public static bool IsOverridePattern(string template)
{
    return template != null &&
        (template.StartsWith("~/", StringComparison.Ordinal) ||
        template.StartsWith("/", StringComparison.Ordinal));
}
```

The `left` part being the controller route and the `right` part being the action route, when the `right` part is an `override pattern`, in other words, contains is preprended by `/` or `~/`, then only the `right` part,  the action route, is used.

# Conclusion

Today we saw how to define routes used attribute route. It is very easy to setup explicit routes. I hope this post removed some of the confusion which can occur with the slash or empty string route. If you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!