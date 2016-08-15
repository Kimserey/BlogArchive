# OOP in Fsharp - How to define and implement classes, abstract classes and interfaces

Even though F# is a functional language, it also provides way to build application in a object oriented way.
When interacting with C# libraries, it is very useful since C# is object oriented by nature.

Today I would like to show you how you can define and build classes in a object oriented way.
This post is composed by three parts:

```
 1. Classes
 2. Abstract classes / interfaces
 3. Inheritance
```

## 1. Classes

Defining classes is the same as defining record type, by using the keyword `type`.
Classes can have `constructors` and `members` which can either be a `function` or a `property`.

```
type MyType(name) =
    let mutable name = name

    do
        () // do some side effect
    
    member self.DoSomething() =
        ()

    member self.PropName 
        with get() = name
        and set value =
            name <- value

    new() =
        new MyType("default name")

let mytype = new MyType()
```

There is a primary constructor defined on the class name `type MyType(name)`.
And members can either be a function like `DoSomething` or a property with a getter and setter like `PropName`.
All side effects must be performed in a `do` statement __before the members__.
Extra constructors can be defined __after the members__ using the `new` syntax.
Lastely __any__ settable properties can be set directly from the empty constructor.


## 2. Abstract classes / interfaces

Interfaces are defined the same way as classes with `type` with `abstract` members.

```
type IMyInterface =
    abstract DoSomething: unit -> unit
    abstract PropName: string with get, set
```

They can define functions like `DoSomething` or properties like `PropName`.

An abstract classes can provide a default implementation for certain members.

```
[<AbstractClass>]
type MyTypeBase() =

    member self.DoSomething() = ()
    abstract PropName: string with get, set
    
    abstract SomeMethod: unit -> unit
    default self.SomeMethod() = ()
```

They must be marked as `AbstractClass`.
`default` implementation of `abstract` members can be provided like we did for `SomeMethod`.
`with get, set` is used to define abstract properties with getter and setter.

## 3. Inheritance

Inheritance of abstract classes is done via `inherit` keyword.

```
type MyType'(name) =
    inherit MyTypeBase()

    let mutable name = name

    do
        base.SomeMethod()

    member self.DoSomething() =
        base.DoSomething()

    override self.PropName
        with get() = name
        and set value =
            name <- value

    new() =
        new MyType'("default name")
```

And implementation of interface is done via explicit implementation.

```
type MyType(name) =
    let mutable name = name

    interface IMyInterface with
        member self.DoSomething() = ()
        member self.PropName
            with get() = name
            and set value =
                name <- value

    new() =
        new MyType("default name")
```

`interface ... with` is used to implement interfaces. To implement multiple interfaces, repeat the `interface ... with` notation.

An other way to implement interfaces is via expression.

```
type IMyInterface' =
    abstract DoSomething: unit -> unit

let x = 
    { new IMyInterface' with
        member self.DoSomething() = () }

x.DoSomething()
```

This way of implementing interfaces is very useful when interacting with C# libraries for functions which requires arguments implementing certain interfaces.

# Conclusion

This was a quick look at how to use F# in a OOP way. We saw how to define classes, abstract classes, interfaces and how to implement those.
F# also provides a neat way to implement interfaces in expression.
I hope you enjoyed reading this post as much as I enjoyed writing it.
If you have any comments, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).
See you next time!

# Other post you will like!

- Extract text from images in F# - [http://kimsereyblog.blogspot.com/2016/05/extract-text-from-images-in-f-ocring.html](http://kimsereyblog.blogspot.com/2016/05/extract-text-from-images-in-f-ocring.html)
- Manage mutable state with F# Mailbox processor - [https://kimsereyblog.blogspot.co.uk/2016/07/manage-mutable-state-using-actors-with.html](https://kimsereyblog.blogspot.co.uk/2016/07/manage-mutable-state-using-actors-with.html)
- Gradient descent in F# to approximate expenses - [https://kimsereyblog.blogspot.co.uk/2016/07/approximate-your-spending-pattern-using.html](https://kimsereyblog.blogspot.co.uk/2016/07/approximate-your-spending-pattern-using.html)
- Computation expression for REST call with WebSharper - [https://kimsereyblog.blogspot.co.uk/2015/08/computation-expression-approach-for.html](https://kimsereyblog.blogspot.co.uk/2015/08/computation-expression-approach-for.html)
