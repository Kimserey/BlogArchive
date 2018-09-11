# Setup Continuous Integration and Deployment for dotnet library with Appveyor and FAKE

[Last week we saw a flow to manage versioning and releases](https://kimsereyblog.blogspot.com/2018/09/versioning-for-open-source-library.html). As a continuation of last week, today I will show how we can setup versioning and releases for open source projects by configuring Appveyor and using FAKE to setup a build script.

1. Configure AppVeyor
2. FAKE

## 1. Configure AppVeyor

Configuring AppVeyor is done via a yaml file `appveyor.yml` at the root of the repository. Then from the site [https://www.appveyor.com/](https://www.appveyor.com/), we can sign in with our GitHub credentials and add the repository to the AppVeyor projects. All the settings in the settings tab can be configured in the yaml file.

`appveyor.yml` settings can be seen in multiple sections:

1. global environment
2. build
3. test
4. artifact
5. deploy

The `global configuration` is where we configure the context of the build,

```yml
# 1.
version: '{build}'
image: Visual Studio 2017
skip_branch_with_pr: true
skip_commits:
  files:
    - docs/**/*
    - '**/*.md'
    - .gitignore
pull_requests:
  do_not_increment_build_number: true
environment:
  VisualStudioVersion: 15.0
  BuildConfiguration: release
```

Here we set the `version` to the build number, `image` to the `Visual Studio 2017` image to have access to msbuild 15, set the build to not build branches with PR as PR themselves are built with `skip_branch_with_pr`, skip the build when commits in only on certain files, and lastly we set some global environment variables like the the build configuration to be `release`.

Next we run some installation prior running the build.

```yml
# 2.
install:
  - ps: choco install gitversion.portable -pre -y

build_script:
  - ps: .\fake run build.fsx -t All
```

`ps: choco install gitversion.portable -pre -y` is used to install [Gitversion which we talked about few weeks ago](https://kimsereyblog.blogspot.com/2018/04/sementic-versioning-for-dotnet.html) and figure out the current version of the application or library to release. `ps: .\fake run build.fsx -t All` runs the FAKE build script which we will define in the second part.

Next we can define how we run tests, for this example we don't have any.

```yml
# 3.
test: off
```

Next we define where the build can find the artifacts, our build script will package the library in a NuGet package `.nupkg` and place them in a `artifacts` folder and we tell AppVeyor that it can find them and upload them from that folder.

```yml
# 4.
artifacts:
  - path: .\artifacts\**\*.nupkg
```

Lastly we setup two deployment, one to `NuGet` and the other one to `GitHub` releases. Each deployment requires a secure key which can be encrypted using the [Encrypt data tool from AppVeyor](https://ci.appveyor.com/tools/encrypt).

```yml
# 5.
deploy:
  - provider: NuGet
    api_key:
      secure: [secure key]
    on:
      appveyor_repo_tag: true

  - provider: GitHub
    description: ''
    release: '$(appveyor_repo_tag_name)'
    artifact: /.*\.nupkg/
    auth_token:
      secure: [secure key]
    on:
      appveyor_repo_tag: true
```

`on` is used to specified when the artifact gets deployed, here we specify that the deployment occurs on tag of the repository [as explained last week](https://kimsereyblog.blogspot.com/2018/09/versioning-for-open-source-library.html).

The full file can be found on my [GitHub on a sample project](https://github.com/Kimserey/hello-world-nuget/blob/master/appveyor.yml) and a reference yaml from AppVeyor can be found on [their documentation page](https://www.appveyor.com/docs/appveyor-yml/).

## 2. FAKE

FAKE is a build tool which allows us to define targets and a pipeline fo building and packaging our .NET projects. Here we use it together with AppVeyor to build and package the application and trigger it in the `build` stage as we seen earlier using the command `ps: .\fake run build.fsx -t All`.

We start first by installing FAKE by running the following command (assuming that `dotnet` is already installed):

```
dotnet tool install fake-cli --tool-path .\.fake
```

This command installs FAKE on a local path under `.fake`. Then we install the `dotnet` FAKE template:

```
dotnet new -i "fake-template::*"
```

And lastly we bootstrap FAKE scripts:

```
dotnet new fake
```

This creates `build.fsx`, `fake.cmd`, `fake.sh` and files under `.fake`. Then we need to run the script first before starting to modify it so that all packages are downloaded via paket `.\fake.cmd build`.
Next we can build the four targets which constitute the build script:

1. Clean
2. UpdateBuildVersion
3. Build
4. Pack

### 2.1 Clean target

`Clean` target is used to clean all folders which need to be cleared before generating the files:

```fsharp
Target.create "Clean" (fun _ ->
    !! "**/bin"
    ++ "**/obj"
    ++ "**/artifacts"
    ++ "gitversion"
    |> Shell.deleteDirs
)
```

### 2.2 UpdateBuildVersion target

Next we deduce the version using `GitVersion` and update the AppVeyor build version using [AppVeyor API](https://www.appveyor.com/docs/build-worker-api/). We start first by defining some utility functions to execute a command and return a result, those will be used to execute the `gitversion /showvariable` command which prints the variable as result.

```fsharp
module Process =
    let private timeout =
        System.TimeSpan.FromMinutes 2.

    let execWithMultiResult f =
        Process.execWithResult f timeout
        |> fun r -> r.Messages

    let execWithSingleResult f =
        execWithMultiResult f
        |> List.head
```

Next we define some utility functions to return the version using `gitversion`.

```fsharp
module GitVersion =
    let showVariable =
        let commit =
            match Environment.environVarOrNone Environment.APPVEYOR_REPO_COMMIT with
            | Some c -> c
            | None -> Process.execWithSingleResult (fun info -> { info with FileName = "git"; Arguments = "rev-parse HEAD" })

        printfn "Executing gitversion from commit '%s'." commit

        fun variable ->
            match Environment.environVarOrNone Environment.APPVEYOR_REPO_BRANCH, Environment.environVarOrNone Environment.APPVEYOR_PULL_REQUEST_NUMBER with
            | Some branch, None ->
                Process.execWithSingleResult (fun info ->
                    { info with
                        FileName = "gitversion"
                        Arguments = sprintf "/showvariable %s /url %s /b b-%s /dynamicRepoLocation .\gitversion /c %s" variable Environment.REPOSITORY branch commit })
            | _ ->
                Process.execWithSingleResult (fun info -> { info with FileName = "gitversion"; Arguments = sprintf "/showvariable %s" variable })

    let get =
        let mutable value: Option<string * string * string> = None

        Target.createFinal "ClearGitVersionRepositoryLocation" (fun _ ->
            Shell.deleteDir "gitversion"
        )

        fun () ->
            match value with
            | None ->
                value <-
                    match Environment.environVarOrNone Environment.APPVEYOR_REPO_TAG_NAME with
                    | Some v -> Some (v, showVariable "AssemblySemVer", v)
                    | None -> Some (showVariable "FullSemVer", showVariable "AssemblySemVer", showVariable "NuGetVersionV2")

                Target.activateFinal "ClearGitVersionRepositoryLocation"
                Option.get value
            | Some v -> v
```

`showVariable` will get the current commit by either looking into the environment variable provided by AppVeyor or deducing the current commit by using `git rev-parse HEAD` and return a function as result which given the `variable` to show will use `gitversion` process either on a remote repository for branches or on the local repository for pull requests.

The command executed for `gitversion` on a remote repostiory is `gitversion /showvariable fullSemVer /url [my-repo.git] /b b-[my-branch] /dynamicRepoLocation .\gitversion /c [sha1]`. This will download locally the repository under `.\gitversion`, and create a branch `b-branch` which will allow `gitversion` to calculate the version based on that branch. Next we define a getter which when invoked declares a final target which cleans the `gitversion` folder and activate it when getter is invoked for the first time.

Lastly we can define the target and use it.

```fsharp
Target.create "UpdateBuildVersion" (fun _ ->
    let (fullSemVer, _, _) = GitVersion.get()

    Shell.Exec("appveyor", sprintf "UpdateBuild -Version \"%s (%s)\"" fullSemVer (Environment.environVar Environment.APPVEYOR_BUILD_NUMBER))
    |> ignore
)
```

### 2.3 Build

For building the application we use the `DotNet.build` from FAKE and specify the `Version` and `FileVersion` parameter for the dll. Provided that we are using the [`SDK-Style` project files](https://kimsereyblog.blogspot.com/2018/08/sdk-style-project-and-projectassetsjson.html), the version and file version can be set via parameter of the build instead of AssemblyInfo.

```fsharp
Target.create "Build" (fun _ ->
    let (fullSemVer, assemblyVer, _) = GitVersion.get()

    let setParams (buildOptions: DotNet.BuildOptions) =
        { buildOptions with
            Common = { buildOptions.Common with DotNet.CustomParams = Some (sprintf "/p:Version=%s /p:FileVersion=%s" fullSemVer assemblyVer) }
            Configuration = DotNet.BuildConfiguration.fromEnvironVarOrDefault Environment.BUILD_CONFIGURATION DotNet.BuildConfiguration.Debug }

    !! "**/*.*proj"
    -- "**/gitversion/**/*.*proj"
    |> Seq.iter (DotNet.build setParams)
)
```

_If you haven't heard of SDK-Style, you can refer to my previous blog post https://kimsereyblog.blogspot.com/2018/08/sdk-style-project-and-projectassetsjson.html._

### 2.4 Pack

The last step is to `Pack`, similarly to build, we use `DotNet.pack` and pass in the `PackageVersion`.

```fsharp
Target.create "Pack" (fun _ ->
    let (_, _, nuGetVer) = GitVersion.get()

    let setParams (packOptions: DotNet.PackOptions) =
        { packOptions with
            Configuration = DotNet.BuildConfiguration.fromEnvironVarOrDefault Environment.BUILD_CONFIGURATION DotNet.BuildConfiguration.Debug
            OutputPath = Some "../artifacts"
            NoBuild = true
            Common = { packOptions.Common with CustomParams = Some (sprintf "/p:PackageVersion=%s" nuGetVer) } }

    !! "**/*.*proj"
    -- "**/gitversion/**/*.*proj"
    |> Seq.iter (DotNet.pack setParams)
)
```

### 2.5 Complete build script

We complete the script by defining the pipeline:

```fsharp
Target.create "All" ignore

"Clean"
  =?> ("UpdateBuildVersion", Environment.environVarAsBool Environment.APPVEYOR)
  ==> "Build"
  ==> "Pack"
  ==> "All"
```

`==>` defines a dependency on the target and `=?>` defines a conditional dependency.
And that's it, here is the complete build script:

```fsharp
#load ".fake/build.fsx/intellisense.fsx"
#nowarn "3180"

open Fake.Core
open Fake.DotNet
open Fake.IO
open Fake.IO.Globbing.Operators
open Fake.Core.TargetOperators

module Environment =
    let [<Literal>] APPVEYOR = "APPVEYOR"
    let [<Literal>] APPVEYOR_BUILD_NUMBER = "APPVEYOR_BUILD_NUMBER"
    let [<Literal>] APPVEYOR_PULL_REQUEST_NUMBER = "APPVEYOR_PULL_REQUEST_NUMBER"
    let [<Literal>] APPVEYOR_REPO_BRANCH = "APPVEYOR_REPO_BRANCH"
    let [<Literal>] APPVEYOR_REPO_COMMIT = "APPVEYOR_REPO_COMMIT"
    let [<Literal>] APPVEYOR_REPO_TAG_NAME = "APPVEYOR_REPO_TAG_NAME"
    let [<Literal>] BUILD_CONFIGURATION = "BuildConfiguration"
    let [<Literal>] REPOSITORY = "https://github.com/Kimserey/hello-world-nuget.git"

module Process =
    let private timeout =
        System.TimeSpan.FromMinutes 2.

    let execWithMultiResult f =
        Process.execWithResult f timeout
        |> fun r -> r.Messages

    let execWithSingleResult f =
        execWithMultiResult f
        |> List.head

module GitVersion =
    let showVariable =
        let commit =
            match Environment.environVarOrNone Environment.APPVEYOR_REPO_COMMIT with
            | Some c -> c
            | None -> Process.execWithSingleResult (fun info -> { info with FileName = "git"; Arguments = "rev-parse HEAD" })

        printfn "Executing gitversion from commit '%s'." commit

        fun variable ->
            match Environment.environVarOrNone Environment.APPVEYOR_REPO_BRANCH, Environment.environVarOrNone Environment.APPVEYOR_PULL_REQUEST_NUMBER with
            | Some branch, None ->
                Process.execWithSingleResult (fun info ->
                    { info with
                        FileName = "gitversion"
                        Arguments = sprintf "/showvariable %s /url %s /b b-%s /dynamicRepoLocation .\gitversion /c %s" variable Environment.REPOSITORY branch commit })
            | _ ->
                Process.execWithSingleResult (fun info -> { info with FileName = "gitversion"; Arguments = sprintf "/showvariable %s" variable })

    let get =
        let mutable value: Option<string * string * string> = None

        Target.createFinal "ClearGitVersionRepositoryLocation" (fun _ ->
            Shell.deleteDir "gitversion"
        )

        fun () ->
            match value with
            | None ->
                value <-
                    match Environment.environVarOrNone Environment.APPVEYOR_REPO_TAG_NAME with
                    | Some v -> Some (v, showVariable "AssemblySemVer", v)
                    | None -> Some (showVariable "FullSemVer", showVariable "AssemblySemVer", showVariable "NuGetVersionV2")

                Target.activateFinal "ClearGitVersionRepositoryLocation"
                Option.get value
            | Some v -> v

Target.create "Clean" (fun _ ->
    !! "**/bin"
    ++ "**/obj"
    ++ "**/artifacts"
    ++ "gitversion"
    |> Shell.deleteDirs
)

Target.create "UpdateBuildVersion" (fun _ ->
    let (fullSemVer, _, _) = GitVersion.get()

    Shell.Exec("appveyor", sprintf "UpdateBuild -Version \"%s (%s)\"" fullSemVer (Environment.environVar Environment.APPVEYOR_BUILD_NUMBER))
    |> ignore
)

Target.create "Build" (fun _ ->
    let (fullSemVer, assemblyVer, _) = GitVersion.get()

    let setParams (buildOptions: DotNet.BuildOptions) =
        { buildOptions with
            Common = { buildOptions.Common with DotNet.CustomParams = Some (sprintf "/p:Version=%s /p:FileVersion=%s" fullSemVer assemblyVer) }
            Configuration = DotNet.BuildConfiguration.fromEnvironVarOrDefault Environment.BUILD_CONFIGURATION DotNet.BuildConfiguration.Debug }

    !! "**/*.*proj"
    -- "**/gitversion/**/*.*proj"
    |> Seq.iter (DotNet.build setParams)
)

Target.create "Pack" (fun _ ->
    let (_, _, nuGetVer) = GitVersion.get()

    let setParams (packOptions: DotNet.PackOptions) =
        { packOptions with
            Configuration = DotNet.BuildConfiguration.fromEnvironVarOrDefault Environment.BUILD_CONFIGURATION DotNet.BuildConfiguration.Debug
            OutputPath = Some "../artifacts"
            NoBuild = true
            Common = { packOptions.Common with CustomParams = Some (sprintf "/p:PackageVersion=%s" nuGetVer) } }

    !! "**/*.*proj"
    -- "**/gitversion/**/*.*proj"
    |> Seq.iter (DotNet.pack setParams)
)

Target.create "All" ignore

"Clean"
  =?> ("UpdateBuildVersion", Environment.environVarAsBool Environment.APPVEYOR)
  ==> "Build"
  ==> "Pack"
  ==> "All"

Target.runOrDefault "Build"
```

## Conclusion

Today we saw how we can setup AppVeyor to build and release a dotnet library. We started by setting up the `appveyor.yml` configuration file to prepare the build agent, build the library, pack it and deploy to NuGet and GitHub. We also saw how to configure the whole FAKE build script with the different targets. Now every time a commit is pushed to any branch on the repository, the AppVeyor build will be triggered and the FAKE build script will run entirely and whenever a tag is pushed, it will trigger a release to NuGet and GitHub release. Hope you liked this post, see you next time!