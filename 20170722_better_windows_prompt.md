# A better dotnet CLI experience with ConEmu

When developing multiple Web api under multiple Visual Studio solutions, it can become very tedious to maintain, run and debug. Opening multiple instances of Visual Studio is very costly in term of memory and running all at once also clutter the screen which rapidly becomes irritating. With the advent of dotnet CLI tools, it has been clear that the next step would be to move out of the common "right click/build, F5" of Visual Studio and toward "dotnet run" on a command prompt.
Last month I was looking for a Windows alternative of the bash terminal which can be found on Mac and I found __ConEmu__.

__ConEmu__ provides access to all typical shells via an enhanced UI. It is actively maintained and open sourced [https://github.com/Maximus5/ConEmu](https://github.com/Maximus5/ConEmu). Today we will see how we can use __ConEmu__ to ease our development process by leveraging only 2 of its features; the tasks and environment setup. This post will be composed by 3 parts:

```
1. dotnet CLI
2. Setup environment
3. Setup tasks
```

## 1. dotnet CLI

We can start first by getting ConEmu from the repository releases [https://github.com/Maximus5/ConEmu/releases](https://github.com/Maximus5/ConEmu/releases).
From now we can start straight using ConEmu as a command prompt. Multi tabs are supported by default, `win + w` shortkey opens a new tab.

Next what we can do is navigate to our Web API project and run `dotnet run`.
This will run the Web API service in the command prompt, here in ConEmu.

It is also possible to restore packages with `dotnet restore` and build a project without running with `dotnet build`.

When the project is ran, it is ran in production mode. This is the default behaviour since usually the production setup is the most restrictive one.
In order to have the environment set to development we can set it by setting it in the current command prompt context:

```
set ASPNETCORE_ENVIRONMENT=Development
```

We would need to run this on every new command prompt window. If we want to persist it, we can set it as a global Windows variable but this will affect the whole operating system. Lucky us ConEmu provides a way to run repeated commands on start of prompt which we will see now.

## 2. Setup environment

At each prompt start, ConEmu allows us to run a set of commands. Those can be used to set environment variables or to set aliases which will exist only in ConEmu context.

In order to access the environment setup, go to `settings > startup > environment` and the following window will show:

![environment]()

From here we can see that we can set variables, here I've set `ASPNETCORE_ENVIRONMENT` and also the base path of all my projects.
And I also set an alias `ns` which helps me to quickly serve an Angular app with Angular CLI `ng serve`.

`ConEmuBaseDir` is the base directory containing ConEmu files. As we can see, `%ConEmuBaseDir%\Scripts` is also set to the path. This `\Scripts` folder is provided by ConEmu and already set to path for us to place scripts in which are then easy access for our tasks.

Now that we know how to setup environment variables, we will no longer need to manually set the `ASPNETCORE_ENVIRONMENT` variable as it will be done automatically. What we still need to do is to navigate to our service and `dotnet run` the project manually. Lucky us, again, ConEmu has a way to automate that by creating a script and setting it to a shortkey with ConEmu tasks which we will see next.

## 3. Setup tasks



# Conclusion