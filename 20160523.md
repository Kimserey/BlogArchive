# Understand the difference between Direct and Inline attributes in WebSharper

In WebSharper, there are two keywords to bind JS code to our F# code - `Direct` and `Inline`.
The documentation about the attributes can be found here [http://websharper.com/docs/translation](http://websharper.com/docs/translation).

I have demonstrated the use of it in previous blog posts:
 - [External JS library with WebSharper in F#](https://kimsereyblog.blogspot.co.uk/2016/01/external-js-library-with-websharper-in-f.html)
 - [Sort, drag and drop in UI Next with Sortable](https://kimsereyblog.blogspot.co.uk/2016/04/drag-and-drop-and-sortable-in-ui-next.html)

Although the documentation has some explanation about it, I still feel like it is pretty vague. 
So today I would like to give more explanation about the differences between `Direct` and `Inline`.

This post is composed by three parts:

1. What is `Direct`?
2. What is `Inline`?
3. Which one to choose and when?

## 1. What is `Direct`?

Even though WebSharper does a very good job to allow us to write JS code in F#,
some functions are still better written in JS directly.
That is where `Direct` comes into action.

`Direct` allows us to create a placeholder functions which can be used anywhere in our code.
During JS translatin, the function body will be replaced by the content of the `string` argument passed to the `Direct` attribute.

```
[<Direct "$x + $y" >]
let add (x: int) (y: int) = X<int>

... somewhere in the code ...
let result = add 1 2
```

This will _kind of_ be translated to*:
```
function($x,$y) {
  return $x+$y;
}

var result = add(1,2)
```
*_It's not really like that but this is close enough to understand._

Here there are three import points to understand:
1. `$` is used to bind the parameters, it is also possible to use `$0`, `$1`, etc... to get the parameters by index
2. `X<_>` is a placeholder value, it is a simple compiler trick for the function to have the correct type returned
3. `Direct` has placed the content in the __body of a function__ and have placed a `return` on the value

Having the content in the a body of a function has another advantage - it allows us to pass a piece of code to `Direct`:

```
[<Direct """
    console.log("Hey");
    console.log("I am adding x and y");
    return $x + $y;
""">]
let add x y = X<int>
```

As you would expect, this is _kind of_ translated to*:
```
function($x,$y) {
  console.log("Hey");
  console.log("I am adding x and y");
  return $x+$y;
}
```
*_It's not really like that but this is close enough to understand._

Here only one point to note:

The `return` keyword has not been placed automatically anymore. This is because the JS code is multiline.
So don't forget the `return` if you want to return a value.

## 2. What is `Inline`?

`Inline` is used to inline the JS code to the call of the function.
That's what the documentation says and that's what it does.
Although the first time I read it, it left me with questions marks.

To understand better, let's see an example.
If we take the previous example and change `Direct` with `Inline` we get:

```
[<Inline "$x + $y">]
let add (x: int) (y: int) = X<int>

... somewhere in the code ...
let result = add 1 2
```
The translation becomes:
```
var result = 1 + 2
```

So that was what the documentation meant.
Everywhere the function `add` is called, the call get replaced by the JS code `x + y`.
__The JS code is inlined to the call of the function.__
Only one restriction to note, since `Inline` is replacing the calls, it can't be multiline.

## Which one to choose and when?

At this point you may be thinking:

__`Direct` and `Inline` both do the same thing except `Inline` has restrictions, I might as well just use Direct.__

Well yes, most of the time I use `Direct` __but in some cases, inlining the code is a necessity__.
A typical example would be when you want to create binding to the members of a JS object.

```
type Location =
    [<Inline "window.location">]
    static member Create() = X<Location>
    [<Inline "$0.href">]
    member x.GetHref() = X<string>

...somewhere in your code...
let href = Location.Create().GetHref()
```
`$0` represents the first parameter, for a member function it is the instance (itself `x` here).

This will get translated to: 
```
var href = window.location.href
```

__What if I used Direct?__

```
[<Direct "$0.href">]
member x.GetHref() = X<string>
```
This would have been translated to
```
window.location.GetHref()
```
which is wrong since `location` doesn't have a member called `GetHref`. You would have had the following error `InlineVsDirect.js:17118 Uncaught TypeError: window.location.GetHref is not a function`.

__In this sample we can't use `Direct`. The code has to be inlined therefore we must use `Inline`.__

## Conclusion

Today we saw the differences between `Direct` and `Inline`.
I tend to use `Direct` more often. I use `Inline` only when I need to define bindings for JS object members. 
But that is just what I experienced so far and there might be other use cases.
I hope this helped you understand better how you could integrate JS code directly into your F# code with WebSharper and
most importantly I hope this demystified the meaning behind `Direct` and `Inline` attributes!
If you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!
