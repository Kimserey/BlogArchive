# SDK-Style project and project.assets.json

Last week I encountered an issue with MSBuild while trying to run it from command line. 
The issue did not appear when using VisualStudio `right click + build` but only appeared when using `msbuild.exe` CLI directly with a clean project.

```
Assets file 'C:\Projects\ConsoleApplication1\obj\project.assets.json' not found. Run a NuGet package restore to generate this file.
```

When I first saw the error, few questions came to my mind which I will share today:

1. Overview of project.assets.json
2. Slim SDK-Style project
3. Mixing SDK-Style project and old projects

Special shoutout to [@enricosada](https://twitter.com/enricosada) who provided me with all the answers regarding the SDK-Style project.

## 1. Overview of project.assets.json

`project.assets.json` lists all the dependencies of the project. It is created in the `/obj` folder when using `dotnet restore` or `dotnet build` as it implicitly calls `restore` before build, or `msbuid.exe /t:restore` with `msbuild` CLI.

To simulate `dotnet build` for .NET Framework project, we can do `msbuild /t:restore;build`

> Building requires the project.assets.json file, which lists the dependencies of your application. The file is created when dotnet restore is executed. Without the assets file in place, the tooling cannot resolve reference assemblies, which results in errors. With .NET Core 1.x SDK, you needed to explicitly run the dotnet restore before running dotnet build. Starting with .NET Core 2.0 SDK, dotnet restore runs implicitly when you run dotnet build. If you want to disable implicit restore when running the build command, you can pass the --no-restore option. 

Source:
[https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-build?tabs=netcore2x](https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-build?tabs=netcore2x)

## 2. Slim SDK-Style project

In the past, all dependencies were listed directly in the project file:

```
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="15.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props" Condition="Exists('$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props')" />
  <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <SchemaVersion>2.0</SchemaVersion>
    <ProjectGuid>453c2b22-326a-4d20-a87a-e43285785f0f</ProjectGuid>
    <OutputType>Library</OutputType>
    <RootNamespace>Library1</RootNamespace>
    <AssemblyName>Library1</AssemblyName>
    <UseStandardResourceNames>true</UseStandardResourceNames>
    <TargetFrameworkVersion>v4.6.1</TargetFrameworkVersion>
    <TargetFSharpCoreVersion>4.4.3.0</TargetFSharpCoreVersion>
    <AutoGenerateBindingRedirects>true</AutoGenerateBindingRedirects>
    <Name>Library1</Name>
  </PropertyGroup>
  <PropertyGroup>
    <MinimumVisualStudioVersion Condition="'$(MinimumVisualStudioVersion)' == ''">11</MinimumVisualStudioVersion>
  </PropertyGroup>
  
  ... lots of other configs ...

  <ItemGroup>
    <Reference Include="mscorlib" />
    <Reference Include="FSharp.Core">
      <Name>FSharp.Core</Name>
      <AssemblyName>FSharp.Core.dll</AssemblyName>
      <HintPath>$(MSBuildProgramFiles32)\Reference Assemblies\Microsoft\FSharp\.NETFramework\v4.0\$(TargetFSharpCoreVersion)\FSharp.Core.dll</HintPath>
    </Reference>
    <Reference Include="System" />
    <Reference Include="System.Core" />
    <Reference Include="System.Numerics" />
    <Reference Include="System.ValueTuple">
      <HintPath>..\packages\System.ValueTuple.4.4.0\lib\net461\System.ValueTuple.dll</HintPath>
      <Private>True</Private>
    </Reference>
  </ItemGroup>
</Project>
```

But since MSBuild 15.0, a new kind of project called [`SDK-Style` project](https://docs.microsoft.com/en-gb/visualstudio/msbuild/how-to-use-project-sdk) is available. It is a slimmer version of the project file and works directly with `dotnet` CLI.

```
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net472</TargetFramework>
  </PropertyGroup>

  <ItemGroup>
    <Compile Include="Library.fs" />
  </ItemGroup>

</Project>
```

This has the big advantage of having the project file now being _developer friendly_. In the past it would be filled with XML tags added by the VS tooling which would prevent developers from changing the project file without fearing breaking the project.
With the SDK-Style or slim project, dependencies are specified in `project.assets.json` generated during `restore` in `/obj`, it is now transparent to developers as it is more of a build step rather than a development step.

```
{
  "version": 3,
  "targets": {
    ".NETFramework,Version=v4.7.2": {...}
  },
  "libraries": {
    "FSharp.Core/4.3.4": {
      "sha512": "...",
      "type": "package",
      "path": "fsharp.core/4.3.4",
      "files": [...]
    },
    "System.ValueTuple/4.5.0": {
      "sha512": "...",
      "type": "package",
      "path": "system.valuetuple/4.5.0",
      "files": [...]
    }
  },
  "projectFileDependencyGroups": {
    ".NETFramework,Version=v4.7.2": [
      "FSharp.Core >= 4.3.4",
      "System.ValueTuple >= 4.5.0"
    ]
  },
  "packageFolders": {...},
  "project": {
    "version": "1.0.0",
    "restore": {...},
    "frameworks": {
      "net472": {
        "dependencies": {
          "FSharp.Core": {
            "target": "Package",
            "version": "[4.3.4, )"
          }
        }
      }
    }
  }
}
```

We can see here all the dependencies, project references, nuget packages, target frameworks, etc... All the information which were previously in the project file are now generated at build time.
Once generated, it is then updated dynamically when removing/adding reference in Visual Studio without the need to build.

There are many advantages for using the SDK-Style projects and those are the ones that affects my daily work:

1. Usage of `dotnet` CLI
2. Slimmer project file more understandable
3. Allow direct editing of the file from VS without the need to unload

**Note:**

It isn't mandatory to be creating a .NET Core application to use the SDK-Style project file. The project file is linked to the version of MSBuild and whether it supports the compilation of the project. Therefore only MSBuild 15.0 will be able to understand it and comes installed with VS2017.
In fact when creating an ASP.NET Core application project on .NET Framework using the VS template, it will create a SDK-Style project targeting .NET Framework.


## 3. Mixing SDK-Style project and old projects

It is not always possible to use the `dotnet` CLI with a SDK-Style project. If the project targets .NET Framework and has dependencies on other projects that aren't SDK-Style projects, the only way to build will still remain using `msbuild.exe /t:restore;build` as the dependent libraries can't be compiled with `dotnet` CLI.

## Conclusion

Today we saw what `project.assets.json` file used for and how we can fix the `Assets file 'C:\Projects\ConsoleApplication1\obj\project.assets.json' not found. Run a NuGet package restore to generate this file.` issue. We then saw what were the differences between a project prior MSBuild 15.0 and a SDK-Style project and what are the advantages of SDK-Style projects. Hope you liked this post, see you next time!