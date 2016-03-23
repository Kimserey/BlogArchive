# How WebSharper.Warp works behind the scene

Lately I've been very happy about how `WebSharper.Warp` allows me to iterate quickly and without pain.
Last week, I covered how we could use WebSharper.Warp to build prototypes quickly. [Check it out if you haven't read it yet](http://kimsereyblog.blogspot.co.uk/2016/03/prototyping-web-app-made-easy-with.html).
Today, I decided to explore how __WebSharper.Warp actually works behind the scene__.

By looking at how `WebSharper.Warp` works, we will learn two things:
 1. The process of compiling F# to WebSharper using `WebSharper.Compiler`
 2. When does the JS files get created
    
## Exploring WebSharper.Warp

`WebSharper.Warp` is a library which allows us to boot a sitelet from a `.fsx` file and run the sitelet from the FSI. 

Here's a short example - if you want better explanation, [I covered it in last week post](http://kimsereyblog.blogspot.co.uk/2016/03/prototyping-web-app-made-easy-with.html).

The following script can be run in a `.fsx`. It boots up a SPA served on `localhost:9000`, with JS code and makes one call to a backend endpoint to get a `Hello!`. We basically get all the power of `WebSharper` to be run from FSI. It makes it easy to rapidly scribble some prototype and run a complete `WebSharper` webapp.

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
        |> View.Map text
        |> Doc.EmbedView

module Server =
    let site =
        Application.SinglePage (fun _-> 
            Content.Page [ client <@ Client.main() @> ])


do Warp.RunAndWaitForInput Server.site |> ignore
```

__How does it work?__

`WebSharper.Warp` is quite fascinating. All the code is contained in a single file [Warp.fs](https://github.com/intellifactory/websharper.warp/blob/master/WebSharper.Warp/Warp.fs).
It combines three steps:
 1. Compiles the files to JS,
 2. Boots up a server
 3. Serves a single endpoint.

It also provides some helper functions to rapidly create sitelets.
It is interesting to look at how `WebSharper.Warp` works as it is _almost the same_ code that runs during MSbuild when [unpacking scripts and content files](https://github.com/intellifactory/websharper/blob/master/src/compiler/WebSharper.Compiler/commands/UnpackCommand.fs).

### Using WebSharper.Compiler

The main function in `WebSharper.Warp` is the `compile` function. It is located in the `Compilation` module and uses `WebSharper.Compiler`.
```
let compile (asm: System.Reflection.Assembly) =
    let loader = getLoader()
    let refs = getRefs loader
    let opts = { FE.Options.Default with References = refs }
    let compiler = FE.Prepare opts (eprintfn "%O")
    compiler.Compile(asm)
    |> Option.map (fun asm ->
        {
            ReadableJavaScript = asm.ReadableJavaScript
            CompressedJavaScript = asm.CompressedJavaScript
            Info = asm.Info
            References = refs
        }
    )
```

This function is used to compile a dynamic assembly which is exactly our case since we are handling a running in `FSI`.
The output of `compile` is a `CompiledAssembly` which exposes intesting members like `ReadableJavaScript`, `CompressedJavaScript` and `Info`.

```
type CompiledAssembly =
{
    ReadableJavaScript : string
    CompressedJavaScript : string
    Info : WebSharper.Core.Metadata.Info
    References : list<WebSharper.Compiler.Assembly>
}
```

The first part of the code in the `compile` function is to get the references from the current assembly with `getRefs`.
```
let loader = getLoader()
let refs = getRefs loader
```
It does a bunch of recursive calls to get the full tree of references (references of references etc) by doing some clever filtering to avoid duplicated references.
The full code of `getRefs` can be found [here](https://github.com/intellifactory/websharper.warp/blob/master/WebSharper.Warp/Warp.fs#L57).
Then it passes those references to a `loader` which will transform it to a `WebSharper.Compiler.Assembly` (to not be confused by the `CompiledAssembly`).
These references are then used to build the options needed to instantiate the `WebSharper.Compiler`.
```
let opts = { FE.Options.Default with References = refs }
let compiler = FE.Prepare opts (eprintfn "%O")
compiler.Compile(asm)
```
The compiler is then used to compile and map the result to a `CompiledAssembly`.
```
compiler.Compile(asm)
|> Option.map (fun asm ->
    {
        ReadableJavaScript = asm.ReadableJavaScript
        CompressedJavaScript = asm.CompressedJavaScript
        Info = asm.Info
        References = refs
    }
)
```

`Compile` is a function from `WebSharper.Compiler` which can be used to compile quotation code or assemblies [https://github.com/intellifactory/websharper/blob/master/src/compiler/WebSharper.Compiler/FrontEnd.fs#L57](https://github.com/intellifactory/websharper/blob/master/src/compiler/WebSharper.Compiler/FrontEnd.fs#L57).

```
/// Attempts to compile an expression potentially coming from a dynamic assembly.
member Compile : quotation: Quotations.Expr * context: System.Reflection.Assembly * ?name: string -> option<CompiledAssembly>
```

Here's a reminder of the full function:
```
let compile (asm: System.Reflection.Assembly) =
    let loader = getLoader()
    let refs = getRefs loader
    let opts = { FE.Options.Default with References = refs }
    let compiler = FE.Prepare opts (eprintfn "%O")
    compiler.Compile(asm)
    |> Option.map (fun asm ->
        {
            ReadableJavaScript = asm.ReadableJavaScript
            CompressedJavaScript = asm.CompressedJavaScript
            Info = asm.Info
            References = refs
        }
    )
```

The next step is to write out the `ReadableJavaScript` and the `CompressedJavaScript` from the `CompiledAssembly`.
The code which is in charge of that is located under the two functions `outputFiles` and `outputFile`.

### Output the files

In the previous code, we loaded the references using the `Loader`. This "loaded assembly" are of type `WebSharper.Core.Assembly`.
They are special in the sense that they carry embedded resources ([more on embedded resources can be found in the doc](http://www.websharper.com/docs/resources)) and also the same properties as the `CompiledAssembly`,
`ReadableJavaScript` and `CompressedJavaScript`.
The following function extracts all the data contained within a WebSharper assembly:
```
let outputFiles root (refs: Compiler.Assembly list) =
    let pc = PC.PathUtility.FileSystem(root)
    let writeTextFile path contents =
        Directory.CreateDirectory (Path.GetDirectoryName path) |> ignore
        File.WriteAllText(path, contents)
    let writeBinaryFile path contents =
        Directory.CreateDirectory (Path.GetDirectoryName path) |> ignore
        File.WriteAllBytes(path, contents)
    let emit text path =
        match text with
        | Some text -> writeTextFile path text
        | None -> ()
    let script = PC.ResourceKind.Script
    let content = PC.ResourceKind.Content
    for a in refs do
        let aid = PC.AssemblyId.Create(a.FullName)
        emit a.ReadableJavaScript (pc.JavaScriptPath aid)
        emit a.CompressedJavaScript (pc.MinifiedJavaScriptPath aid)
        let writeText k fn c =
            let p = pc.EmbeddedPath(PC.EmbeddedResource.Create(k, aid, fn))
            writeTextFile p c
        let writeBinary k fn c =
            let p = pc.EmbeddedPath(PC.EmbeddedResource.Create(k, aid, fn))
            writeBinaryFile p c
        for r in a.GetScripts() do
            writeText script r.FileName r.Content
        for r in a.GetContents() do
            writeBinary content r.FileName (r.GetContentData())
```
For each references, it writes the readable JS and compressed JS into its own file.
Then move on to get all the scripts linked from resources, writes those in files.
And finally gets all the contents like Css files or images, and writes those in files as well.

For the `CompiledAssembly`, it is straightforward as the only step needed is to write the readable JS and compressed JS into files.
```
let outputFile root (asm: CompiledAssembly) =
    let dir = root +/ "Scripts" +/ "WebSharper"
    Directory.CreateDirectory(dir) |> ignore
    File.WriteAllText(dir +/ "WebSharper.EntryPoint.js", asm.ReadableJavaScript)
    File.WriteAllText(dir +/ "WebSharper.EntryPoint.min.js", asm.CompressedJavaScript)
```

This is why, _at the moment_ (some rumor that it might become much faster in the near future), compiling with WebSharper is a two step process:
 1. Compile with msbuild which makes a .dll
 2. Compile that .dll with `WebSharper.Compiler` which makes a `CompiledAssembly`

## Conclusion

By understanding `WebSharper.Warp`, we got a better insight on the steps required by `WebSharper` to compile an assembly.
It also showed us how .fsx files could be compiled and translated to JS and at which moment were the JS files actually created. 
Hope this helped you understand better the mystery behind `WebSharper.Warp`. Like always if you have any comments, hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). Thanks for reading!
