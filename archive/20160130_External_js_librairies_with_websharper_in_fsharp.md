# External JS library with WebSharper in F#

When building web apps with WebSharper in F#, one of the most common question is: 
- __How do we integrate external JS library with WebSharper in F#?__

It is indeed an interesting question since one of the good side of JS is the number of good libraries out there which will save you a lot of time and effort.

WebSharper provides directives to call external JS libraries within F#. Today I would like to explore how we can integrate a JS libraries into our WebSharper project with `UI.Next`.
I will demonstrate how you can extend `WebSharper.JQuery` to add a tag input functionality with autocompletion.
For the tag input and formatting we will use [Bootstrap Tags Input library](https://github.com/bootstrap-tagsinput/bootstrap-tagsinput) and to provide autocompletion, we will use [Typeahead.js](http://twitter.github.io/typeahead.js/).

Here's a preview of the result:

![preview tag input](http://4.bp.blogspot.com/-mQdegAmYZ9M/VqwEz5ZjmQI/AAAAAAAAAEE/q3fv0-Mx4y0/s1600/tag.gif)

## Understand how to use the JS library first

`Tags input` with `Typeahead.js` works as an extension of `JQuery`. 
To use it, you needs to define an `input` with an attribute `data-role="tagsinput"`.
```
<input id="tags" data-role="tagsinput" />
```
And call `.tagsinput` from `JQuery` on your input by passing a configuration which contains the `typeahead` configuration source.
```
$('#tags').tagsinput({
  typeaheadjs: {
    source: function(query, callback) { 
               callback(["something";"something else"]);
    }}});
```
In this example I just set the `source` property which is a function called to fetch the data to present in the autocompletion. It is called every time the input is modified.the first argument is the value of the input and the second argument is a callback used to populate the autocompletion dropdown.

## Build a link from F# to the JS librairy

WebSharper provides two directives to interact with JS libraries `Direct` and `Inline`. `Direct` will allow you to link a JS function to an F# signature and call it as if it was in F#. `Inline` will do the same but will inline the JS translation to the call function. You can find the documentation [here](http://websharper.com/docs/translation).

As we saw earlier, `tags input` is built as an extension method of `JQuery`. WebSharper has the bindings to `JQuery` already built in so what we want is to extend `WebSharper JQuery` to put `tags input` just how it is done in JS.
In F#, it is possible to extend types by using the `with` keyword and omitting the `=`. It allows us to write the following:
```
open WebSharper
open WebSharper.JavaScript
open WebSharper.JQuery

[<JavaScript>]
module Client =
     type JQuery with
         member this.TagsInput source = X<unit>
```
`X<unit>` is provided by WebSharper and indicates to WebSharper that this method is just a placeholder and that it does not have any implementation. You can view it as a placeholder implementation, it tells WebSharper to look for the JS implementation instead of the F# implementation.

So far we just defined an F# definition which serves as a bridge between our F# code and the JS code. To define the JS code, we need to use the Inline attribute. Here's how to do it:
```
     type JQuery with
        [<Inline "$0.tagsinput({ typeaheadjs: { source: $1 }})">]
        member this.TagsInput
(source: FuncWithArgs<string * (string [] -> unit), unit>) = X<unit>
```
First we add the `Inline` attribute and place the JS code in quotes. If you compare both, the original JS and the one in quote, you will notice that the only differences are the special characters `$0` and `$1`.
```
$('#tags').tagsinput({ typeaheadjs: { source: function(q, cb) { callback(["something";"something else"]); }}})
$0.tagsinput({ typeaheadjs: { source: $1 }})
```
Those special characters represent the arguments of the F# function where `$0` represents the current instance this, it will be our `JQuery` instance since the function is an extension of `JQuery` and `$1` is the first argument. Here we have only one argument of type `FuncWithArgs<string * (string [] -> unit), unit>`.

When we give a tuple as argument of function, WebSharper can't tell whether we want a tuple as argument or if we want a function with multiple arguments. In our case, `source` is a function with two arguments so giving it a tuple will result in a single argument which is incorrect. To indicate to WebSharper that we want a function with multiple arguments, we must use `FuncWithArgs<input, ouput>` ([thanks to István for the info](http://websharper.com/question/81141/how-to-translate-js-callbacks-with-two-arguments)).
Then if we examine the input type `string * (string [] -> unit)`, we have a tuple composed by the `query string` and a `callback` function taking an array of string to show in a autocompletion dropdown and returning unit. This signature represents exactly what `source` is.

We are done now with the link from F# to JS libraries.

## How do we call it?

We now have a bridge to the JS library ready to be used. We need to create the input and call the `JQuery` extension.
```
let input = inputAttr [ attr.id "tags"
                        Attr.Create "data-role" "tagsinput" ] []
input |> Doc.RunById "main" // provided that you have a div with an id="main"
```
And we can now instantiate our `tag input` by calling the extension we created earlier:
```
let onChange (query, callback) =
    // this is called every time the query change
    callback [| "Something"; Something else"  |]

JQuery.Of(input.Dom).TagInput (FuncWithArgs <| onChange)
```
## Conclusion

Today we saw how easy it is to integrate an external JS library and create a bridge between our F# code in WebSharper and some functions of the JS library, you can find the full code [here](https://gist.github.com/Kimserey/1454d2501295dca22075). Of course you can use that for other libraries, It is very useful and I have done it this way for few libraries like Bootstrap or Cropbox, you can have a look at the implementation of [my Cropbox bridge to F# here](https://gist.github.com/Kimserey/6696bfea49d91074eef7) and it worked pretty well for me. Hope you enjoyed this tutorial, like always hit me on twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam) if you have any comments  and thanks for reading!




