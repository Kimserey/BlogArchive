# Build your UI framework

## 1. Start with SCSS

An introduction to SCSS

Configure VS with Gulp.

[https://github.com/Kimserey/SimpleUI](https://github.com/Kimserey/SimpleUI)

## 2. Push to GitHub and reference in your webapp

Push your repository to GitHub.

## 3. Use Paket with GitHub dependency to make a file dependency

Some instruction to get running with Paket can be found here:
[https://kimsereyblog.blogspot.co.uk/2016/01/quick-setup-with-paket-and-fsx-scripts.html](https://kimsereyblog.blogspot.co.uk/2016/01/quick-setup-with-paket-and-fsx-scripts.html)

In paket.dependencies add:

```
github Kimserey/SimpleUI css/SimpleUI.css
github Kimserey/SimpleUI js/SimpleUI.js
```

Then run 
```
.paket\paket.exe update
```

Add the 2 files as `Embedded resource`.

Boot a WebSharper SPA and add the following:

```
namespace SimpleUIWeb

open WebSharper
open WebSharper.Resources
open WebSharper.JavaScript

module Resources =
    
    type Fontawesome() =
        inherit BaseResource("https://use.fontawesome.com/269e7d57ca.js")

    type Css() =
        inherit BaseResource("SimpleUI.css")
    type Js() =
        inherit BaseResource("SimpleUI.js")

    [<assembly:Require(typeof<Fontawesome>);
      assembly:Require(typeof<Css>);
      assembly:Require(typeof<Js>)>]
    do()

[<JavaScript>]
module Client =
    open WebSharper.UI.Next
    open WebSharper.UI.Next.Html
    open WebSharper.UI.Next.Client
    
    let Main =
        Console.Log "Started"
```

Tutorial on how to manage resources with `BaseResource` and `Require attribute` can be found here:
[https://kimsereyblog.blogspot.co.uk/2016/06/three-ways-to-manage-your-resources-for.html](https://kimsereyblog.blogspot.co.uk/2016/06/three-ways-to-manage-your-resources-for.html)

The full code source can be found here:
[https://github.com/Kimserey/SimpleUIWeb](https://github.com/Kimserey/SimpleUIWeb)

# Conclusion
