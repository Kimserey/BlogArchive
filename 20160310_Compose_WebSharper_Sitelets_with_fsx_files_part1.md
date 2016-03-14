# Compose WebSharper Sitelets with .fsx files

Recently I had the requirement to build a webapp which needed to handle multiple customers. 
The way we did it was to place pages into two buckets, __common__ and __bespoke__.
__Common__ pages would refer to pages shared for all customers and __bespoke__ pages would refer to pages unique to each customers. 
We achieved this by building a WebSharper sitelet composed by common pages contained in a library and bespoke pages contained in .fsx script files. .fsx files are the perfect fit for this scenario as we needed to be able to compile only a subset of it depending on the customer we were building the webapp for. Also .fsx files are self contained which make it even more appealing.

In this post, we will see how we can build a sitelet composed by code taken from a library but also from .fsx files.
At the same time, we will have a better understanding of the steps required to compile a `WebSharper.Sitelet` by understanding how and when does the extraction of the JS files happens.


This post will be composed by 3 parts:
  1. Understand how to call `WebSharper.Compiler` by having a look at `WebSharper.Warp`.
  2. Using `FSharp.Compiler.Services` to compile .fsx files.
  3. Use the result of the execution of the .fsx files to build a sitelet and host it on a `Owin` selfhost

## Part 1 - Exploring WebSharper.Warp

Having this requirement in hand, I started to search for a solution to compile F# with `WebSharper.Compiler` and I found [`WebSharper.Warp`](https://github.com/intellifactory/websharper.warp).
`Warp` allows us to boot a sitelet from an .fsx file and run the sitelet from the FSI. 

The following script is all the code required to bootup a server which serves a single page application returning hello world:
```
open WebSharper
open WebSharper.Html.Server

do
    Warp.CreateSPA (fun ctx -> [H1 [Text "Hello world!"]])
    |> Warp.RunAndWaitForInput
    |> ignore
```

__How does it work?__

`Warp` is quite fascinating. All the code is contained in a single file [Warp.fs](https://github.com/intellifactory/websharper.warp/blob/master/WebSharper.Warp/Warp.fs).
It combines three steps:
 1. Compiles the files to JS,
 2. Boots up a server
 3. Serves a single endpoint.

It also provides some helper functions to rapidly create sitelets.
It is interesting to look at how `Warp` works as it is _almost the same_ code that runs during MSbuild when [unpacking scripts and content files](https://github.com/intellifactory/websharper/blob/master/src/compiler/WebSharper.Compiler/commands/UnpackCommand.fs).

### Using WebSharper.Compiler

The main function in `Warp` is the `compile`. It is located in the `Compilation` module and uses `WebSharper.Compiler`.
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

This function is used to compile a dynamic assembly which is exactly our case since we are handling a dynamic assembly (`FSI assembly`).
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

The first part of `compile` is to get the references from the current assembly with `getRefs`.
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

This first part was an overview of `Warp`. By understanding `Warp`, we got a better insight on the steps required by `WebSharper` to compile an assembly.
It also showed us how .fsx files could be compiled and translated to JS and at which moment were the JS files actually created. 
In the Part 2, we will see how we can use `FSharp.Compiler.Services` to directly compile a sitelet composed by .fsx files and extract in into a variable to be used in our webapp.
Like always if you have any comments, hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). Thanks for reading!
