# Compose WebSharper Sitelets with .fsx files

Recently I had the requirement to build a website composed by .fsx files.
We can create a webapp which is composed by common functionalities and enhance it with specific functionalities provided in .fsx files.
This allows us to handle multiple versions of our webapp within the same solution.
It is very interesting in the case where you need to provide bespoke functionalities to your customers but with the overall same structure.
The common functionalities which rarely change will be in a _normal_ library whereas the bespoke customer functionalities will live in .fsx files which are easily _scriptable/throwable_ based on customer needs.

Having this requirement in hand, I started to search for a solution to compile F# with `WebSharper.Compiler` and I found [`WebSharper.Warp`](https://github.com/intellifactory/websharper.warp).
`Warp` allows us to boot a sitelet from an .fsx file and run the sitelet from the FSI. This kind of solve half of the problem already.
The next challenge was to combine a common sitelet built with a _normal_ library with this compilation of .fsx and finally boot all that in a `Owin` selfthost.

__What this post is going to give you?__

This post aims to give you better understanding of the steps required to compile a `WebSharper.Sitelet` and how and when does the extraction of the JS files happens.
It also aims to provide a solution to handling multiple customers with different requirements without having to branch your project.

We will look closely at `WebSharper.Warp` to see how we can use the code to turn it into our advantage.

## Exploring WebSharper.Warp

I find [`Warp`](https://github.com/intellifactory/websharper.warp/blob/master/WebSharper.Warp/Warp.fs)
 quite fascinating. It uses the `WebSharper.Compiler` to compile an assembly and extract out of the assembly the JS code which can then be written into output files and it also extract the metadata needed to run the sitelet.
 The main function of `Warp` is `compile`.

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
From this method we extract a `CompiledAssembly` which exposes members we are interested in, like `ReadableJavaScript`, `CompressedJavaScript` and `Info`.

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
It does a bunch of recursive calls to get the full tree of references (references of references etc) by doing some clever filtering to avoid duplicated references.
Then it passs those references to a `loader` which will transform it to a `WebSharper.Compiler.Assembly` (to not be confused by the `CompiledAssembly`).
These references are then used to build the options `let opts = { FE.Options.Default with References = refs }` 
needed to instantiate the `WebSharper.Compiler` `let compiler = FE.Prepare opts (eprintfn "%O")` which is then used to compile the current dynamic assembly.

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

With the `CompiledAssembly` we then have everything we need because as the name of the member indicates it, `ReadablleJavaScript` is the non minified JS and `CompressedJavaScript` is the minified JS.
`Core.Metadata.Info` contains the metadata needed for the sitelet to run properly, without it `RPC` calls will not work for example.

The references `WebSharper.Compile.Assembly` and the `CompiledAssembly` are then used to write the outputs files in the functions `outputFile` and `outputFiles`.

`outputFiles` generates the JS files from the references and also generates the content files like embedded resources used in sitelets. [More on embedded resources can be found in the doc](http://www.websharper.com/docs/resources).

`outputFile` generates the JS files related to the current compiled assembly.

This is why, _at the moment_, compiling with WebSharper is a two step process:
1. Compile with msbuild which makes a .dll
2. Compile that .dll with `WebSharper.Compiler` which makes a `CompiledAssembly`

After we are done compiling and we have the compiled assembly, we can write the JS into files that we place in our root folder.

### Dig into Warp compile method



## Bind everything in an Owin selfhost

## Conclusion
