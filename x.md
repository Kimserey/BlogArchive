# Use F# script files as configuration files

I have been using F# script files (.fsx) as configuration file for a while now instead of using json files.
Like everything, there are advantages and disadvantages. 
Today I will talk about the advantages and disadvantages of using fsx for configuration files then I will proceed to show how to implement it.
This post is composed by 2 parts:
  
```
1. Advantages and disadvantages
2. Implementation
```

## 1. Advantages and disadvantages

Type safety is one of the biggest advantage provided by `fsx`. We define a Configuration type in a library and implement the type in `fsx` so when extracting the implementation from the `fsx`, we can be sure that all members are present.
The second advantage is that we can leverage useful F# types like option type.
The last advantage is that we can define function types and members 

The disadvantage being that the process of using `fsx` file needs a compilation therefore it will take few seconds to compile and extract the result from the compilation.

As a rule of thumb, when my configuration has a large number of members, I favorite the use of `fsx` files over `json` files. And when the configuration requires function, I always go for `fsx`.

## 2. Implementation

First we start by creating the configuration type. It will have some members of different types and include a function just for example.

```
```

Now that we have the configuration type, we can create the fsx which will contain the implementation of the configuration.
 
```
```

We will have different versions of the configuration separated in different folders.

```
```

Next we need to be able to extract the configuration from the fsx. In order to do that we need to compile the fsx from code. We do that by using the `FSharp.Compilation.Service`.

```
```

Like that when we run the program we can extract the configuration desired by using the argument given to the entry point.

One example would be to be able to configure a website for multiple customers. The infrastructure is the same but the properties display different information and the mapping function is different.

# Conclusion

Today we saw how we could use fsx files as configuration file to replace commonly used json files. Fsx is very versatile as it allows to configure normal properties but also functions. It can be contained in the application or coming from an external location, all we need to do is to compile it and extract the desired configuration. I hope you like this post! If you have any question leave it here or hit me on Twitter [@Kimserey_Lam](). See you next time!

# Other posts you will like!
