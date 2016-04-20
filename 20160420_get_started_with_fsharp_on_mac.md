# Get started with F# on Mac with VSCode and Ionide

Yesterday, a friend of mine asked me what was the easiest way to get started with F# on Mac.
I pointed him to [http://fsharp.org/use/mac/](http://fsharp.org/use/mac/) which gives multiple options to install F# on Mac but it doesn't contain the option
of using [VSCode](https://code.visualstudio.com/) with [Ionide](http://ionide.io/).
Since I think it is the most straight forward way to have an environment setup to use of F# rapidly especially when someone wants to just have a quick look, I decide to write a blog post to go through the installation step by step.

The steps are:
 1. Install brew
 2. Install mono from brew
 3. Install VSCode
 4. Install Ionide
 5. Write a .fsx script make everything works

## 1. Install brew

[http://brew.sh/](http://brew.sh/)

To install `brew`, start a terminal and paste the following:

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

![brew](https://2.bp.blogspot.com/-MCdhqT2VVGE/Vxf5gXg719I/AAAAAAAAAGI/FmlU3mhjblQemL2FKIYjmXUDJLjaMeDdACLcB/s1600/brew.png)

Homebrew is a package manager. We will use it to install `mono`.
After executing the command, you should have access to `brew` from the terminal.

## 2. Install mono

> Mono is an open source implementation of Microsoft's .NET Framework

To install `mono`, start a terminal and paste the following:

```
brew install mono
```

![mono](https://3.bp.blogspot.com/-EQP6-tULonI/Vxf5hk9yjpI/AAAAAAAAAGQ/pKmEGwdBzxoC_skP-otcXYga1WdZleDJgCKgB/s1600/mono.png)

After you installed `mono`, you should have access to `fsharpi`.
`fsharpi` is the fsharp interactive also called `FSI`.

![fsi](https://4.bp.blogspot.com/-qUlUJqwRKQw/Vxf7SokgA6I/AAAAAAAAAGg/fOfugxwQ-Ok_krBmfe5jMK1UeDAkSdvlwCLcB/s1600/fsharpi.png)

## 3. Install VSCode

[https://code.visualstudio.com/](https://code.visualstudio.com/)

Install Visual studio code [https://code.visualstudio.com/](https://code.visualstudio.com/).
Visual studio code is a code editor which also allows developpers to write plugins against it.
Thanks to the amazing work of [@k_cieslak](https://twitter.com/k_cieslak), we can use F# with VSCode using [Ionide](http://ionide.io/).
Ionide is a package suite which provides interaction with `FSI`, autocompletion, syntax highlighting and many more amazing things.

## 4. Install Ionide

[http://ionide.io/](http://ionide.io/)

If we go to the Visual studio marketplace and look for Ionide,
we should be able to `find ionide-fsharp` [https://marketplace.visualstudio.com/items?itemName=Ionide.Ionide-fsharp](https://marketplace.visualstudio.com/items?itemName=Ionide.Ionide-fsharp)

Below __Installation__, the website gives us an indication on how to install the packge on VSCode.

```
Launch VS Code Quick Open (⌘+P), paste the following command, and type enter.

ext install Ionide-fsharp
```

![ionide](https://3.bp.blogspot.com/-4AbVmTg0EW8/Vxf5gYrsSaI/AAAAAAAAAGE/e02IqTqaMxoiPYZ_2iRpzN-PtfYWuCWWQCKgB/s1600/ionide_install_on_vscode.png)

That's it, you have all the necessary tools to write code in F# now.

## 5. Write a .fsx script make everything works

Now that you have all the stuff needed. Create a `.fsx` file and paste the following:

```
let helloWorld =
    "Hello world from FSI"

printfn helloWorld
```

Select the whole text and hit `ALT + ENTER`.
If everything is alright, this command will execute the highlighted code in the FSI.

![fsi_code](https://1.bp.blogspot.com/-Mo6uhXQn0aA/Vxf9DcnTdtI/AAAAAAAAAGs/_Zfxedc07v4tmQwTnwAESiIXbjcNSNkJwCLcB/s1600/helloworldfsx.png)

# Conclusion

Today we saw a quick way to get started with F# scripts. As a starter I would suggest to look at an example from [@ScottWlaschin](https://twitter.com/ScottWlaschin) website [https://fsharpforfunandprofit.com/](https://fsharpforfunandprofit.com/). Have a look at the tic tac toe example. coming from an OOP language, it was really helpfull [https://fsharpforfunandprofit.com/posts/enterprise-tic-tac-toe/](https://fsharpforfunandprofit.com/posts/enterprise-tic-tac-toe/).
Hope this was helpful, if you have any issue, please let me know here or hit me on Twitter [https://twitter.com/Kimserey_Lam](https://twitter.com/Kimserey_Lam)!
