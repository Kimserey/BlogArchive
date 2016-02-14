# Improving developer feedback loop in WebSharper.UI.Next with FAKE

In my previous posts I explained how to use WebSharper in different ways with Sitelet to build complete backend + frontend web app and with UI.Next to build reactive front end. 
If you built the samples, you would have realised that for every changes, a compilation is required to build the JS files.
Last week [@Tobias_Burger](https://twitter.com/toburger) [asked me](https://kimsereyblog.blogspot.co.uk/2016/01/architecture-for-web-app-built-in-f-and.html?showComment=1454496891390#c879113901600675581link) whether I knew a way to improve developer feedback loop when developing web app with WebSharper and that is the subject of this post - __Improving developer feedback loop in WebSharper.UI.Next with F#.__

__What is a feedback loop?__

In this post case, a feedback loop is referred as a way to propagate changes from the code to the UI and get a visual feedback from it. 
Having fewer steps between writing and visualising results in faster feedbacks which indirectly improves developer experience. 
A great example is - building a web app in JS. 
For JS, saving the files is enough to propagate changes and only a refresh of the page is needed. 
In contrast, an app with WebSharper requires the project to be recompiled when changes are made. Therefore, more actions are required before having a visual feedback.

This post is organised in three sections:

1. Understand how WebSharper.UI.Next build JS
2. Brief introduction of FAKE
3. Improve feedback loop with FAKE file watcher

## Understand how WebSharper build the JS files

WebSharper generation of JS files is handled by a `MSBuild` Target `WebSharper.targets` which in located in the `\build` folder of the WebSharper package. 
It is normally imported automatically and the following import can be found in the `.fsproj`:

```
<Import Project="..\packages\WebSharper.3.6.7.227\build\WebSharper.targets" Condition="Exists('..\packages\WebSharper.3.6.7.227\build\WebSharper.targets')" />
```

There are few properties to be configured in the .fsproj in order for WebSharper to compile the JS properly therefore the easiest way to create projects is to use the VS project templates. The most important parameter is 'WebSharperProject'. 'WebSharperProject' is used to indicate the type of application being compiled. I have only used three: 'Site', 'Bundle' and 'Library'.
- Site is used to compile JS for a backend+frontend app
- Bundle is used to compile JS for a frontend only app
- Library is used to compile a library to WebSharper without generating JS files

This post explores how WebSharper compiles JS files for frontend apps. For that, the VS template WebSharper Client side application will create an empty project already configured. The 'Bundle' project type is used.

Here are the steps taken by WebSharper to compile the JS files
- Project get compiled into a dll
- Dlls are used by WebSharper to produce 'WebSharper compiled' dlls containing metadata
- Depending on the project type JS files are created from the metadata contained within the dlls

Every time the code is updated, the process needs to be rerun. In other word, to propagate changes from the code to the UI, the dll needs to be recompiled first, then recompiled with WebSharper and finally the browser needs to be refreshed to rerun the new JS.

How can we improve the development experience?

Compiling the project and refreshing the browser are disruptive to the development, the former being worse since it might take time to compile the project and to extract the JS files. Therefore a first step toward improvement of development experience would be to make the compilation lesser disruptive and that is what FAKE will be used for.

2 - Brief introduction to FAKE

In development, every project has its own build workflows and specifications. There are times where it is preferable to 'Clean + Build', times where it is preferable to 'Clean + Build + Run Tests', some projects need to be deployed to Azure and some need to pushed to NuGet. [FAKE](http://fsharp.github.io/FAKE/) helps automating all these workflows through script. It provides a panoply of helpers which give support for FTP, Git, Azure, MSBuild and many more.

Taking the example of 'Clean + Build + Run Tests', each stage of the workflow is called a 'Target' in FAKE. 'Clean + Build + Run Tests' workflow will have three separate targets 'Clean', 'Build' and 'RunTests'. Targets aren't limited to a single workflow, they can't be reused and combined to create other workflows. For example with 'Clean', 'Build' and 'RunTests' it is possible to define two useful workflows: 'Clean + Build' and 'Clean + Build + RunTests'. A target is composed by a name and an action.

/// Creates a Target.
val Target : name:string -> body:(unit -> unit) -> unit
Target "Clean" (fun () -> trace "Cleaning folders...")
Target "Build" (fun () -> trace "Building something...")
Target "RunTests" (fun () -> trace "Running tests...")

The definition of a workflow is done using [the infix operator '==>'](https://github.com/fsharp/FAKE/blob/master/src/app/FakeLib/AdditionalSyntax.fs#L66).  The arrow defines the flow, A ==> B means that to run A, B must be run first. Taking the previous two flows:

///Clean + Build + Run Tests
 "Clean"
    ==> "Build"
    ==> "RunTests"

///Clean + Build
"Clean"
    ==> "Build"

Running a target is done by calling 'RunTargetOrDefault targetName'.
Lastly the full script must be run using 'FAKE.exe' in the \tools folder. A target name can be provided as argument. If no argument is provided, FAKE will run the default given to 'RunTargetOrDefault'.

packages\FAKE.4.20.0\tools\FAKE.exe build.fsx RunTests

How can FAKE help in our task to improve feedback loop?

One of the issue was the constant need to build the solution to propagate changes. It turns out that FAKE provides a file watcher helper which triggers an action every time the files watched are changed. This is how FAKE can help in improving feedback loop - FAKE can automate the build of the WebSharper project every time a files are changed.

3. Improve feedback loop with FAKE file watcher

The improvement proposed by this post is to automate the build so that every time a file is changed, the solution is rebuilt and the JS is regenerated. This is achieved using FAKE watcher. A watcher is built using the ['WatchChanges' function](http://fsharp.github.io/FAKE/apidocs/fake-changewatcher.html). It requires two arguments, the action to run every time changes are detected and a list of files to watch. Files to watch are declared using the [function '!!'](https://github.com/fsharp/FAKE/blob/master/src/app/FakeLib/Globbing/FileSystem.fs#L88) which takes a string pattern to detect the files.
 
//Watch all files .fs files in the subdirectories
let files = !! "**/*.fs"

The MSBuild helper exposes functions to build solution. The function 'build' (https://github.com/fsharp/FAKE/blob/master/src/app/FakeLib/MSBuildHelper.fs#L330) is used to build the solution, it takes a function which is used to configure the MSBuild parameters and a solution file path.

In the watcher documentation, the watcher directly calls a target but this causes some issues as the target only runs once https://github.com/fsharp/FAKE/issues/791. The fix is to extract the code into function calls and call this functions in order in the watcher.

let build() =
    build id "SampleFakeWatcher.sln"

Target "Build" build

Target "Watch" (fun _ ->
    use watcher = !! "**/*.fs" |> WatchChanges (ignore >> build)
    System.Console.ReadLine() |> ignore
    watcher.Dispose()
)

RunTargetOrDefault "Watch"

Running the build script is done by passing it as argument to FAKE.exe. The name of the target can also be passed as a second argument.

Packages/tools/FAKE.exe build.fsx Watcher

After running the build script, FAKE is now automatically rebuilding the solution everytime the files are changed.
With this in place, when building a clientside application with UI.Next, every time the files are changed, the update is directly propagated and the only step needed is to refresh the browser. Thanks to the watcher, the manual building step can be removed as it is triggered on file saved and developers only need to refresh the browser.

IMAGE

Conclusion

Today the focus was on improving developer feedback loop. We explored FAKE watcher to automate build of solution and JS files with WebSharper. FAKE is a very powerful tool which offers a lot of possibility. To find more complex examples of build scripts, you can refer FAKE owns build script (https://github.com/fsharp/FAKE/blob/master/build.fsx) or the FSharp.Data build script (https://github.com/fsharp/FSharp.Data/blob/master/build.fsx). As usual if you have any comments hit me on twitter [@Kimserey_Lam](https://twitter.com/kimserey_lam). Hope you enjoyed reading this post as much as I enjoyed writing it. Thanks for reading!