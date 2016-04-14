# Proxies in WebSharper, how, when, where!

When I first started to play with WebSharper, everything was nice and clean.
I was coding in my own world/sandbox/project whatever you want to call it.
But the thing is that most of the time, we don't start from empty, blank project.
What we do instead, is that we write code which integrate with an existing application.
And if we are lucky enough, we work in a project with a backend written in F# with a `Domain` library containing all the application domain written in F# as well.
Being in this situation, the first think I tought of was:

__Wouldn't it be amazing if I could use the `Domain` library directly in my webapp?__

Well we can! And we will see how in this post.
There are multiple scenarios when referencing libraries.
In this post we will address the following requirements:
 1. I want to __only__ use the record types defined in `Domain` library
 2. I want to use the record types __and/or__ the functions attached to the record types in `Domain` library
 3. I want to use the functions from a module in `Domain` library

__The fastest way is to reference WebSharper in `Domain` libary and add `[<JavaScript>]` to the main module or to every types and functions.__
__If you are not willing to do that, you might need to proxy the functions depending on your needs. We will see how.__

[The full code sample is available on github](https://github.com/Kimserey/WsProxyExample).

## I want to use the record types defined in `Domain`

If you just need to use the record types from `Domain`, you need to reference WebSharper and add `<WebSharperProject>Library</WebSharperProject>` to `fsproj`.
This indicate to WebSharper that this project needs to be compiled to JS.

If you can't add WebSharper to the project and/or can't add the configuration to `fsproj`, you will need to `proxy` the record type.
You can find the official documentation [here](https://github.com/intellifactory/websharper/blob/master/docs/Proxies.md).

As an example, let's pretend that your `Domain` library contains the follwing type:
```
type Dog =
    { Name: string
      Age : int }
```

If you want to `proxy` this type you will do the following in the project where you need to use that type:
```
[<JavaScript; Proxy(typeof<Dog>)>]
type Dog' =
    { Name: string
      Age: int }
```

In this example I created a type `Dog'` which `proxies` the type in the `Domain` library.
Thanks to that, in your client code, you can handle a `Dog` instance even though it won't be compiled to JS.

```
[<JavaScript>]
module Client =  

    let dog: Dog =
        As({ Name = "dog"
             Age = 5 })
    
    let main =
        text dog.Name
        |> Doc.RunById "main"
```
We create a `Dog'` and then use `As` to cast it to a `Dog`. We can then call the members. 

__But what if `Dog` had some functions associated with it?__

## I want to use the record types with the functions attached to the record types from `Domain` library

Again, if you can, reference WebSharper to the library and add the configuration `<WebSharperProject>Library</WebSharperProject>` to `fsproj`.
But this time on top of that, you have to decorate your type or module with `[<JavaScript>]`.
```
[<JavaScript>]
type Dog =
    { Name: string
        Age : int }

    static member Walk (x: Dog) =
        x.Name + " is walking!"
```
This indicates to WebSharper that the functions need to be translated to JS. 
Without `[<JavaScript>]`, the compilation will fail if you call `Walk` from your client code as WebSharper will not be able to find `Walk`.

If you can't do that, then you will have to `proxy` the function. Just how we proxied the type earlier:
```
[<JavaScript; Proxy(typeof<Dog>)>]
type Dog' =
    { Name: string
      Age: int }

    static member Walk(x:Dog)  =
        x.Name + " is walking! - from proxy"
```
By adding the function to the `proxy`, we managed to `proxy` the type and its function.
We can now call the function from our client side code.

```
[<JavaScript>]
module Client =  

    let dog: Dog =
        As({ Name = "dog"
             Age = 5 })
             
    let main =
        [ text (dog.Name)
          br [] :> Doc
          text (Dog.Walk dog) ]
        |> Doc.Concat
        |> Doc.RunById "main"
```

And the page will display `dog is walking! - from proxy`. It executes the content of the `proxy` instead of looking for the original.
You can also `proxy` a function with some JS code.
This is helpful because sometime things just don't have a direct translation and you have to provide it manually.
You can do that by using `Direct` or `Inline`.
```
[<JavaScript; Proxy(typeof<Dog>)>]
type Dog' =
    { Name: string
      Age: int }

    [<Inline "$x.Name + ' said hello instead of walking.'">]
    static member Walk(x:Dog)  = X<string>
```

If you never seen this attribute before, [you can have a look here at a previous post I made on how to use external JS libraries](http://kimsereyblog.blogspot.co.uk/2016/01/external-js-library-with-websharper-in-f.html).

## I want to use the functions from a module in `Domain` library

Let's say now you have a function in a module. It's different than the previous examples as instead of having it attached to a type, it is directly defined in a module.
```
module Garden =
    open Animal

    let runInGarden (x: Cat) =
        x.Name + " is running in the garden!"
```
Again, the easiest way is to reference WebSharper and add the configuration `<WebSharperProject>Library</WebSharperProject>` to `fsproj` and `[<JavaScript>]` attribute to the module.

```
[<JavaScript>]
module Garden =
    open Animal

    let runInGarden (x: Cat) =
        x.Name + " is running in the garden!"
```

If you can't do it, you will have to `proxy` the function. The difference here is that `Garden` is a module and not a type therefore we can't do `typeof<Garden>`.
What we need to do is specify that we wan't to `proxy` the module by giving the full name of the module. 
For me the library is called `Domain` and the module `Garden`, so the `proxy` is defined like so:

```
[<JavaScript>]        
[<Proxy "Domain.Garden, Culture=neutral">]
module Garden' =

    let runInGarden (x: Cat) =
        x.Name + " run in second garden! - from proxy"
```

With that in place, you can call `runInGarden` and the `proxy` will be executed.

[The full code sample is available on github](https://github.com/Kimserey/WsProxyExample).

## Conclusion

We have seen most of the possibilities on how to reference a F# library with WebSharper.
The main question that I wanted to answer here was whether it was possible to reference a library which itself has no reference to WebSharper and still be able
to use the type and functions defined in it. The answer is yes. You just need to `proxy` it. 
The advantage of `proxying` libraries is that you still use a set of familiar functions as those are your domain defined signatures.
In fact, that's how WebSharper give access to the .NET libraries, by `proxying` most of the types. You can find all the proxy [under stdlib/WebSharper.Main/Proxy](https://github.com/intellifactory/websharper/tree/5c884e97fd3dba1102c10a85b171f672d0b3f637/src/stdlib/WebSharper.Main/Proxy).
I hope this post helped in demystifying how we can make our own proxy to use our own libraries! If you have any comments leave it here or hit me on Twitter @Kimserey_Lam(https://twitter.com/Kimserey_Lam). See you next time!
