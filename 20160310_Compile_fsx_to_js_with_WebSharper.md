# Compose WebSharper Sitelets with .fsx files

Recently I had the requirement to build a website composed by .fsx files.
We can create a webapp which is composed by common functionalities and enhance it with specific functionalities provided in .fsx files.
This allows us to handle multiple versions of our webapp within the same solution.
It is very interesting in the case where you need to provide bespoke functionalities to your customers but with the overall same structure.
The common functionalities which rarely change will be in a _normal_ library whereas the bespoke customer functionalities will live in .fsx files which are easily _scriptable/throwable_ based on customer needs.

Having this requirement in hand, I started to search for a solution to compile F# with `WebSharper.Compiler` and I found [`WebSharper.Warp`](https://github.com/intellifactory/websharper.warp).
`Warp` allows us to boot a sitelet from an .fsx file and run the sitelet from the FSI. This kind of solve half of the problem already.
The next challenge was to combine a common sitelet built with a _normal_ library with this compilation of .fsx and finally boot all that in a `Owin` selfthost.

## Compile to JS with WebSharper.Compiler

## Compile the .fsx files with FSharp.Compiler

## Bind everything in an Owin selfhost

## Conclusion
