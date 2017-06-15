# Quick setup with Paket and .fsx scripts

Paket is a dependency manager. It is useful especially when you want to develop `.fsx files` where the full path of the dependencies are hardcoded in your script. It makes it easier to manage dependencies compared than using Nuget because the version of the library isn't included in the path.

This post will show how to setup a new .fsx file with dependencies handled by Paket.

## Initialize Paket and download libraries
Download `paket.boostrapper.exe` from [here](https://github.com/fsprojects/Paket/releases/tag/2.44.6).
Place it under `\.paket` and run it:
```
.paket\paket.bootstrapper.exe
```
It will download the latest version of `paket.exe`. Now run `init` to initialize paket for your solution:
```
.paket\paket.exe init
```
Your solution is now ready to get the libraries. Now to install a library run:
```
.paket\paket.exe add project TestProject nuget MathNet.Numerics.FSharp
```
`project` is used to specify a project and `nuget` is used to specify a nuget package to be downloaded.
After running the command, you will now have `MathNet.Numerics` in your packages folder and you will be able to reference it from your `.fsx` script files.
```
#load @"..\packages\MathNet.Numerics.FSharp\"MathNet.Numerics.fsx"

open MathNet
open MathNet.Numerics.LinearAlgebra
open MathNet.Numerics.Statistics

let x = vector [ 2.0; 5.0 ]
let y = matrix [ [ 1.0; 2.0 ]
                 [ 3.0; 4.0 ] ]

let z = x * y
```
When I started F#, I was confused by `#I`, `#r` and `#load`. I also didn't really know what to google to look for explanation. Actually the explanation are in `F# interactive reference` [here](https://msdn.microsoft.com/en-us/library/dd233175.aspx) and this is what the directives do (copy pasted from msdn):
- `#I`: Specifies an assembly search path in quotation marks.
- `#load`: Reads a source file, compiles it, and runs it.
- `#r`: References an assembly.

In our case, `MathNet.Numerics` came with a `MathNet.Numerics.fsx"` which contains all the references needed to use the library so we just need to load that script.

If `MathNet.Numerics` have updates, you just need to run the `update` command and your packages will be updated. Your script files won't need to be changed.
```
.paket\paket.exe update
```

## Conclusion
It is very easy to manage dependency with Paket. And I've showed you how to quickly and easily add dependency when you just want to hack things in a `.fsx file`. There is much more that can be done with Paket, you can convert a Nuget solution to Paket, you can also reference git depedencies, git gist, even http dependencies like fssnip for example. All this can be found in the [doc](https://fsprojects.github.io/Paket/getting-started.html). Thanks for reading!