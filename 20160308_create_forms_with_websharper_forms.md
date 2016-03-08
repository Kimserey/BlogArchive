# Creating forms with WebSharper.Forms

In previous posts, I have covered multiple aspects of how to use WebSharper to make nice webapps by using [animations](http://kimsereyblog.blogspot.co.uk/2016/03/create-animated-menu-with.html), 
by taping into [external JS libaries](http://kimsereyblog.blogspot.co.uk/2016/01/external-js-library-with-websharper-in-f.html) or by using the built in [router in UI.Next to make SPA](http://kimsereyblog.blogspot.co.uk/2015/08/single-page-app-with-websharper-uinext.html).
Today I would like to cover another aspect which is essential for making useful webapps - __Forms__.

Most of the site we visit on a daily basis have forms. `WebSharper.Forms` is a library fully integrated with the reactive model of `UI.Next` which
brings composition of forms to the next level by making composition of forms, handling validation,
handling submit and displaying error an easy task.

## What is needed to build a form

The form that we will build in this tutorial will handle:
- Inline validation
- Submitting data
- Async operation
- Error handling from async operation

![preview](https://raw.githubusercontent.com/Kimserey/forms/master/form.gif)

This are the requirements I gathered during my last project. I have a many forms but overall, they all require this four points and not more.

## Composing with WebSharper.Forms

All the forms that I built so far follow the same order of instructions:
1. Calls `Form.Return`,
2. Follows a bunch of apply (`<*>`) of `Form.Yield`,
3. Pipes (`|>`) `Form.WithSubmit` to tell it that I want to submit something,
4. Pipes some async function `Form.MapAsync` which are to be executed on submit,
5. Pipes `Form.MapToResult` to handle the result of the async call,
6. Pipes `Form.Render` which provides a way to transform the `Form` to a `Doc` which we can then embed in the page

As an example, here is the full implementation of the form that we will use:

```
Form.Return (fun firstname lastname age -> firstname + " " + lastname, age)
<*> (Form.Yield "" |> Validation.IsNotEmpty "First name is required.")
<*> (Form.Yield "" |> Validation.IsNotEmpty "Last name is required.")
<*> (Form.Yield 18)
|> Form.WithSubmit
|> Form.MapAsync(fun (displayName, number) -> sendToBackend displayName number)
|> Form.MapToResult (fun res -> 
    match res with
    | Success s -> Success s
    | Result.Failure _ -> Result.Failure [ ErrorMessage.Create(customErrorId, "Backend failure") ])
|> Form.Render(fun name lastname age submit ->
    form [ fieldset [ div [ Doc.Input [] name ]
                        Doc.ShowErrorInline submit.View name
                        div [ Doc.Input [] lastname ]
                        Doc.ShowErrorInline submit.View lastname
                        div [ Doc.IntInputUnchecked [] age ]
                        Doc.Button "Send" [ attr.``type`` "submit" ] submit.Trigger 
                        Doc.ShowCustomErrors submit.View ] ])
```

The first part of the form composed by the set of `Return <*> yield <*> yield <*> yield` is very powerful.
It allows us to work directly with the input results in the function given in `Form.Return`. 
Because we are working within the `Form`, the values given to the function in `Form.Return` are _always valid_.
As we can see, validation on the inputs is done at the `Yield` level.

Looking at the type, the first `Form.Return` has the following type:

```
Form<'T, 'D -> 'D>
Form<(string -> string -> int -> string * int), ('a -> 'a)>
```
 
And `Form.Yield ""` has the following type:
 
```
Form<string, ((Var<string> -> 'a) -> 'a)>
```

Applying `Yield` to `Return` (putting them together with `<*>`) will combine the types and returns:

```
Form<(string -> int -> string * int), ((Var<string> -> 'a) -> 'a)>
```

We basically removed one of the `string` params from `'T` and added a `Var<string>` param in `'D`.
By continuing the same way, `Form.Yield ""` and `Form.Yield 0`, we end up with:

```
Form<(string * int), ((Var<string> -> Var<string> -> Var<int> -> 'a) -> 'a)>
```

And it turns out that `string * int` is our inputs combined in a tuple that we receive in the `Form.MapAsync` as argument 
and `Var<string> -> Var<string> -> Var<int>` is what we receive in `Form.Render` to render our form.
Wonderful, it __seems__ to add up together!

### Inline validation
Inline validation refers to the validation of the fields before being sent. It will help to prevent submitting the form for nothing.
I might be stating the obvious but __the server should still perform a validation on the input sent__.

Validation is handled during `Form.Yield` piped to `Validation.XX`.

__What happens when data is invalid?__

That's the amazing part, when data is invalid, the function in the `Form.Return` isn't executed.
Instead a `Failure` is passed through and can be caught in the `Form.Render` to be displayed.
That is why we can safely assume that all the arguments in the `Form.Return` function are valid arguments and we can perform the action we want.

### Submitting data

When we want to use a `submit` button and we want the form to be `triggered` when that `submit` button is clicked,
we need to pipe a `Form.WithSubmit` function. This adds a special type at the end of the arguments of `'D`.
The type becomes:

```
Form<(string * int), ((Var<string> -> Var<string> -> Var<int> -> Submitter<Result<string * int>> -> 'a) -> 'a)>
```

The `Submitter` type exposes a `Trigger` function which allows the form to be triggered and a `View` which observe the `Result<'T>` of the form.
The `View` can be used to display inline errors and errors returned from the `async call`.

### Mapping async function and result

Most of the time when sending a form we want to perfom a network request.
Those requests are usually `async request`. `Form.MapAsync` allows us to specify an `async` function to be executed when the form is submitted.
This allows us to handle the result in `Form.MapToResult` without worrying about the `async` nature of the call.
`Form.MapToResult` is piped to perform an action when the result of the `async` function is returned.

### Render

Finally we render the form and transform it to a `Doc`. As we seen earlier, the arguments of the `Render` function are the `Var<_>` plus a `Submitter`.
We basically construct the form and call `.Trigger` on click.

## Some helpers

The `Render` call contains some extra functions, `Doc.ShowErrorInline` and `Doc.ShowCustomErrors`. 
These functions are extensions that I have created to simplify the display of errors.
Here's the implementation:

```
let customErrorId = 5000

type Doc with
    static member ShowErrorInline view (rv: Var<_>)=
        View.Through(view, rv) 
        |> View.Map (function Success _ -> Doc.Empty | Failure errs -> errs |> List.map (fun err -> p [ text err.Text ] :> Doc)  |> Doc.Concat) 
        |> Doc.EmbedView
    static member ShowCustomErrors view =
        Doc.ShowErrors view
            (fun  errs ->  errs 
                            |> List.filter (fun err -> err.Id = customErrorId)
                            |> List.map    (fun err -> p [ text err.Text ] :> Doc)  
                            |> Doc.Concat) 
```

`View.Through` will filter the errros which are only related to the `Var<_>` given. 
I am using a `cutomErrorId` to filter the errors that I created myself.

## Conclusion

At first `WebSharper.Forms` looks intimidating, especially when you are not familiar with the apply notation.
But the concept of the `Form` is very powerful as it allows us to _hide_ behind the `Form` type and manipulate safe values to perform our actions.
The only validation needed is the validation during the `Yield` stage. After that even the errors in the `async` is handled.
After getting used to it, I found the use of `WebSharper.Forms` very beneficial as 
it allowed me to rapidly build form flows and even after few weeks, 
I can just have a glance at the code and directly understand what it is doing 
(and we all know that it does not happen with every piece of code). Like always, if you have any comments, don't hesitate to hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam) or leave a comment below.
Thanks for reading!
