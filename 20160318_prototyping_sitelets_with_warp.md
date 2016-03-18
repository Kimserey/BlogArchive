# Prototyping Sitelets with WebSharper.Warp

Scripting quick prototypes in WebSharper can sometime be troublesome. 
If for each prototype, a new project has to be created or code needs to be commented/uncommented, it will soon be demotivating as too many steps are required to start new prototypes.
In F#, `.fsx` files are a great tool to script disposable code.
Write some isolated functions, run on FSI and then throw the file.

With WebSharper, it is possible to __script a complete sitelets__ in `.fsx` files using `WebSharper.Warp` [https://github.com/intellifactory/websharper.warp](https://github.com/intellifactory/websharper.warp).

In this post, I will show you how I setted up my project in order to use `Warp` efficiently to create sitelet prototypes.
Building with `.fsx` is a __huge__ advantage. It allows us to have multiple files containing completely isolated sitelets all within the same project.
Therefore we can boot up easily through a one line command any sitelet to test it quickely which makes it ideal for prototyping.

## Get WebSharper.Warp

There are two ways to get `WebSharper.Warp`. The first way is through Nuget and the second way is through Paket.

__Although, for anything related to `.fsx`, I would strongly recommend using Paket.__

If you are unfamiliar with Paket you can read the [doc here](https://fsprojects.github.io/Paket/) or [checkout an older post I made about it](http://kimsereyblog.blogspot.co.uk/2016/01/quick-setup-with-paket-and-fsx-scripts.html).
So we will be using Paket here.

Run the Paket command:
```
tools\paket.exe add nuget WebSharper.Warp
```

This should install `Warp` in your `\packages` folder. It should also installed all the references of `Warp` including `WebSharper`, `WebSharper.UI.Next` and others.
`Warp` also comes with an extra folder `\tools` where you should find `reference-nover.fsx`. 
This file contains all the reference links to be loaded from your `.fsx` file so that you don't need to reference everything by yourself.
You just need to load `reference-nover.fsx` at the head of your `.fsx`:
```
#I "../packages/"
#load "WebSharper.Warp/tools/reference-nover.fsx"
```

_This is one of the reason why I recommended to use Paket. If we were to use Nuget, the path would break each time `WebSharper` is updated because Nuget puts the version number in the path._
_Another reason why is that we don't need to add the reference to any project. We just need the libraries to be downloaded in a folder in order for us to reference it from our fsx._

For the moment, some references are missing from `reference-nover.fsx`, [I've made a PR](https://github.com/intellifactory/websharper.warp/pull/18).
Until this is merged, you will need to alter `reference-nover.fsx` to add `WebSharper.UI.Next.Templating.dll` and `Intellifactory.Xml.dll` if you want to use the html templates in your sitelets.

Now that we have `Warp` ready and we have loaded it, we can start creating our first sitelet.

## Start a sitelet

Let's start by creating a very simple sitelet:

```
#I "../packages/"
#load "WebSharper.Warp/tools/reference-nover.fsx"

open WebSharper
open WebSharper.JavaScript
open WebSharper.Sitelets
open WebSharper.UI.Next
open WebSharper.UI.Next.Html
open WebSharper.UI.Next.Client

module Remoting =
    [<Rpc>]
    let sayHello() = 
        async.Return "Hello!"

[<JavaScript>]
module Client =
    let main() =
        View.Const ()
        |> View.MapAsync Remoting.sayHello
        |> Doc.BindView text

module Server =
    let site =
        Application.SinglePage (fun _-> 
            Content.Page [ client <@ Client.main() @> ])


do Warp.RunAndWaitForInput Server.site |> ignore
```

We use `Application.SinglePage` which is a helper to boot SPA with a single endpoint.

The interesting part is `Warp.RunAndWaitForInput`.
This function takes a sitelet as argument.
If you run this code in FSI, it will boot a selfhosted server on `http://localhost:9000/` (by default).

This is fantastic because what we can do is create a `buildAndRun.cmd` file which will execute the script so that we can easily restart the sitelet without having to manually sent the code to the FSI.
It consists of one single command line.

```
C:\"Program Files (x86)"\"Microsoft SDKs"\F#\4.0\Framework\v4.0\fsi.exe %*
```

And now we can run in our command prompt:
```
buildAndRun.cmd Simple_Sitelet.fsx
```

Now because `Warp` allows us to boot a complete sitelet, we can also reference external resources.
Say we want to add Bootstrap, one way to do it is by using the html template.

_Remember you need to add the libraries in reference-nover.fsx_

We can create a html file `index.html` which loads Bootstrap and place it where our script is:

```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>-</title>
    <meta name="generator" content="websharper" data-replace="scripts" />
    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous" />
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>
</head>
<body>
    <div data-replace="body">
    </div>
</body>
</html>
```

And then use it as template with our sitelet:

```
module Server =

    type Page = { Body: Doc list }

    let template =
        Content.Template<Page>(__SOURCE_DIRECTORY__ + "/index.html")
            .With("body", fun x -> x.Body)
    
    let site =
        Application.SinglePage (fun _ ->
            Content.WithTemplate template
                { Body = [ client <@ Client.main() @> ] })
```

With that we have all the ingredients to create powerful sitelet within a `.fsx` file:
 - RPCs
 - External resources
 - JS compilation
 - Boot on Owin selfhost

## Benefits

__But what's the benefits?__

The major benefits is that it makes prototyping much easier. 
When I started to use WebSharper, I used to create a new project, SPA project or Sitelet project with WebSharper template each time I had to test something.

It was slow and demotivating. I then started to just keep the same project and everytime I had to test something, I would delete the previous code.

With `WebSharper.Warp`, only one `.fsx` needs to be created. It is easy and quick and you can be up and running a full sitelet in a matter of seconds.
This makes prototyping much more enjoyable and combined with the build script, it is quick and easy to iterate.

## Conclusion

Today we saw how we could use `WebSharper.Warp` in a very efficient way. 
Prototyping is one of the best way to take advantage of `Warp` since it is so easy to get started!
I hope you will try it and let me know if you have other tricks to make your journey with `WebSharper` even more enjoyable.
As usual, if you have any comments please leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).
Thanks for reading!
