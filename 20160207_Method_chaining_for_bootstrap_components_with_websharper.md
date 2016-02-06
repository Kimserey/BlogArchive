#Method chaining for Bootstrap components with WebSharper in F#

Lately I have been playing extensively with WebSharper and have been working on improving the structure and reusability of Bootstrap components built with WebSharper. I like writing HTML from F# as it allows me to reuse code by using namespaces and modules to group reusable functions and elements. 

Over the last couple of month, I have tried many ways to make functions which facilitate the creation of Bootstrap components and tried many ways to group them into meaningful modules so that it is easily findable for the next time I want to use them. Out of all the solutions I've tried, only one really stood out and it is what I want to share today - __Method chaining to build Bootstrap components__.

If you want to follow this tutorial, here are the steps that I took before starting to write any code:
- Getting WebSharper templates from github here,
- Create a new WebSharper.UI.Next single page application
- Add bootstrap CSS and JS in index.html

##Method chaining

Method chaining comes from the OOP world. It is the act of creating methods on an object which alters the object and returns itself. For example, we could do the following:

```
var dog = new Dog()
            .WithName(“Cookie”)
            .WithOwner(“Kim”)
            .WithAge(“5”)
```

Each `.Withxxx()` methods return `dog instance` with its property altered. Method chaining is usually used in Fluent API to build human readable api methods and make the discovery of methods easier.

__But how does Method chaining will help us with WebSharper and Bootstrap?__

Bootstrap has a lot of UI components and each elements have multiple configurations. For example, a form can align its inputs vertically, horizontally or  inline all the inputs.The nav tabs can be displayed as tabs or pills and when it is displayed as pills, it can be represented vertically. Bootstrap offers a rich set of components that can be used to suit our needs and the best way to know it all is to read the [documentation](http://getbootstrap.com/components/#nav). Read for the first time the documentation is good but reading the documentation over and over again hoping to know by heart the whole framework isn’t a great solution, at least it doesn’t work for me as I tend to forget after few hours… So we need an abstraction of Bootstrap in F# which will allows us to easily discover all the features and configurations of Bootstrap. This can be achieved with the help of __Method chaining__.

##WebSharper and HTML

WebSharper exposes some functions to create HTML tags under [WebSharper.UI.Next.Html](https://github.com/intellifactory/websharper.ui.next/blob/master/WebSharper.UI.Next/HTML.fs). Each HTML tag has its equivalent, for `<div>` you will find `div` to create divs without attributes or `divAttr` for those with attributes, for `<table>` you will have `table` and `tableAttr`. To specify attribute you can use `Attr` or `attr` like so `pAttr [ attr.``class`` “text-muted” ] [ text “Hello world.” ]`. The first argument of each xAttr function takes a list of `attr` and the second argument is a list of `Doc`. A `Doc` is a representation of a `DOM element`, it can be any ensemble of elements.

For this tutorial, we will take as example the creation of [Nav tabs](http://getbootstrap.com/components/#nav-tabs) as it is quite complex already and there are few ways to configure tabs which will have a look.

![example Nav tabs](https://4.bp.blogspot.com/-qAzlnGKaik0/VrZ1wSLhSxI/AAAAAAAAAEY/hfXVUEnGQ_4/s1600/Screen%2BShot%2B2016-02-06%2Bat%2B22.37.25.png)

For example one possibility of creating Nav tabs would be:

```
<ul class="nav nav-tabs">
  <li role="presentation" class="active"><a href="#">Home</a></li>
  <li role="presentation"><a href="#">Profile</a></li>
  <li role="presentation"><a href="#">Messages</a></li>
</ul>
```

Which translates to this with WebSharper:

```
ulAttr [ attr.``class`` “nav nav-tabs” ]
       [ liAttr [ Attr.Create “role” “presentation”
                  attr.``class`` “active” ]
                [ aAttr [ attr.href “#” ] [ text “Home" ]  ]
...
```

As you can see it mimics quite closely the HTML but it involves a lot of strings to define the CSS classes and the attributes. If I wanted to reuse this element, I would have to rewrite it. On top of that, it takes quite some time to understand again what the code is actually modelling. Also this is only one possible way to create Nav tabs. There are many other possibilities like what we talked earlier.

__So how can I expose the power of Bootstrap without having to rewrite the WebSharper HTML code?__

We will do it in two steps:
     
1. List down all the possible combinations
2. Use Method chaining to build a comprehensive type which will create nav tabs menu

##List down the combinations

First we will start by looking at the possibilities offered by nav tabs. I have listed below the combinations that I found (I probably forgot some but that will be enough to convey the idea behind this post. ):

- The nav can be display as tabs
- The nav can be display as Pills
- The nav can be justified (take the whole width available)
- Pills can be stacked vertically
- Tabs can have an active state
- Tabs can have a disable disable

From this list we can already separate the possibilities in three groups. One group affecting the nav in general, another group which is affecting only the nav when it is displayed as pills and the last one affecting one tab.

##Create NavTabs type

Now that we are aware of the possibilities we can start writing our NavTabs type. Taking the first three configuration affecting the nav in general, we defines whether the nav is tabs or pills and whether it is justified or not:

```
type NavTabs = {
     Tabs: NavTab list
     NavTabType: NavTabType
      IsJustified: bool
}
and  NavTabType =
| Normal
| Pill
```

Then we can move on to the tabs which can be normal, active or disable:

```
type NavTabState = {
     Id: string
     Text: string
     Content: Doc
     State: NavTabState
}
and NavTabState =
| Normal
| Active
| Disabled

Lastly we need to revisit our NavTabType as our last requirement is to allow Pills to be stacked. We do that by specifying it in the NavBarType:

type NavTabs = {
     Tabs: NavTab list
     NavTabType: NavTabType
     IsJustified: bool
}
and  NavTabType =
| Normal
| Pill of PillStack
and PillStack =
          | Horizontal
          | Vertical
```

Here’s the complete code of the NavTabs type:
...
...

Now we have all the configurations and if we want to create a nav tabs with 3 tabs, justified with pills in an vertical layer, we would write:

```
let nav = {
     Tabs = [  { Id = “first-tab”; Text = “First tab”; Content = Doc.Empty; State = Active }; { … }; { ... }  ]
     NavTabsType = Pill Vertical
     IsJustified = true
}
```

We’ve got all the foundation to make nav tabs but there is one problem with that: we need to specify all members even when most of the time we will have the same configuration. I say “most of the time” because it is important as there will be time where those configuration will be required. So how can we make it easier to initialise all the members and create nav tabs in a more pleasant way? That’s where we will use Method chaining to construct a human readable set of functions to help us initialise it.

##Method chaining with NavTabs

As we explaining at the beginning the purpose of Method chaining is to provide a set of functions which are human readable and which make it easy to discover what kind of configuration we can have for our types. The first thing we need to do is to have a first function to create the type as a default state.

```
type NavTabs with
     static member Create() = { Tabs = []; NavTabType = Normal; IsJustified = false }
```

We are now in a better position to create nav tabs as we can just call NavTabs.Create(). The next step would be to provide a function to add tabs.

From this method we get a default configuration. What we need next is to make the other configurations available. We will do that by following the .Withxxx pattern we employed in our example of method chaining.

On the navtabtype we will then have:

```
type NavTabs with
     static member Create() = { Tabs = []; NavTabType = Normal; IsJustified = false }
     member x.WithTabs tabs = { x with Tabs = tabs }
     member x.Justify isJustified = { x with IsJustified = isJustified }
     member x.WithNavTabType navTabType = { x with NavTabType = navTabType }
```

We do the same for the tab type with a create function

```
type NavTab with
     static member Create id = ...
     member x.WithTitle title = ...
     member x.WithContent content = ...
     member x.WithNavTabState state = ...
```

Now when we want to make the same example as before with three tabs, pills and justified, we need to write:

```
let tabs =
    NavTabs.Create()
            .Justify(true)
            .WithType(Pill Vertical)
            .WithTabs(
                [ NavTab.Create("home")
                        .WithTitle("Home")
                        .WithContent(text "Home page here.")
                        .WithState(NavTabState.Active)

                    NavTab.Create("account")
                        .WithTitle("Account")
                        .WithContent(text "Account page here.")

                    NavTab.Create("profile")
                        .WithTitle("Profile")
                        .WithContent(text "Profile page here.")

                    NavTab.Create("hello")
                        .WithTitle("Hello")
                        .WithState(NavTabState.Disabled) ])
```

This is longer to write then the previous one where we define everything ourself but this method has multiple advantage. First every time you hit “.” you will get an autocompletion which is helpful to discover all the available configurations. Secondly and most importantly, when you want to create just default nav tabs (with tabs horizontal, non justified) you just need to write:

```
NavTabs.Create().WithTabs([ … ])
```

There will be no need to configure the other members. We are now done with creating the nav tabs, the last bit remaining is to render the tab. To do that we need to take our crafted record and transform it to a WebSharper Doc. This component is kind of special as it is composed by two distinct components: the tabs and the contents. For that we will need two render functions on NavTabs and NavTab.

Let start by NavTab with RenderTab and RenderContent:

```
type NavTab with
     member x.RenderTab() =
            liAttr [ attr.role "presentation"
                      attr.``class`` (match x.State with
                                     | NavTabState.Normal -> ""
                                     | NavTabState.Active -> "active"
                                     | NavTabState.Disabled -> "disabled") ]
                   [ (match x.State with
                      | NavTabState.Disabled -> aAttr [ attr.href “#” ] [ text x.Title ]
                      | _ ->  aAttr [ attr.href ("#" + x.Id)
                                           Attr.Create “role” “tab"
                                           Attr.Create “data-toggle” “tab” ]
                                         [ text x.Title ]) ]
     member x.RenderContent() =
            divAttr [ Attr.Create “role" "tabpanel"
                          attr.id x.Id
                          attr.``class`` (match x.State with NavTabState.Active -> "tab-pane fade in active" | _ -> "tab-content tab-pane fade") ]
                        [ x.Content ]
```

The Render functions transform our crafted record type to a WebSharper Doc by pattern matching over all the configurations and translating it to the correct HTML and CSS classes. We do the same for NavTabs:

```
type NavTabs with
     member x.RenderTabs()=
            ulAttr [ attr.``class`` ("nav "
                                           + (if x.IsJustified then "nav-justified " else "")
                                 + (match x.NavTabType with
                                        | Normal -> "nav-tabs"
                                        | Pill Horizontal -> "nav-pills"
                                        | Pill Vertical -> "nav-pills nav-stacked")) ]
                      (x.Tabs |> List.map NavTab.RenderTab |> Seq.cast)
     member x.RenderContent() =
            divAttr [ attr.``class`` "tab-content" ] (x.Tabs |> List.map NavTab.RenderContent |> Seq.cast)
```

Finally we can call Render on the NavTabs record to get a doc and display it on the screen. The result code to create nav tabs is the following:

```
let tabs =
    NavTabs.Create()
            .Justify(true)
            .WithType(Pill Vertical)
            .WithTabs(
                [ NavTab.Create("home")
                        .WithTitle("Home")
                        .WithContent(text "Home page here.")
                        .WithState(NavTabState.Active)

                    NavTab.Create("account")
                        .WithTitle("Account")
                        .WithContent(text "Account page here.")

                    NavTab.Create("profile")
                        .WithTitle("Profile")
                        .WithContent(text "Profile page here.")

                    NavTab.Create("hello")
                        .WithTitle("Hello")
                        .WithState(NavTabState.Disabled) ])

tabs.Render()
|> Doc.RunById “main"
```

And here is the result:

![result image](https://3.bp.blogspot.com/-VAK2kyZD7w0/VrZ0_3oekoI/AAAAAAAAAEU/a0fxK-zK0_I/s1600/Screen%2BShot%2B2016-02-06%2Bat%2B21.16.57.png)

##Conclusion

Today we explore a way of creating kind of a DSL to build Bootstrap components with WebSharper in F# using Method chaining. This approach has the advantage of being very flexible and easy to extend. With the code being very readable, it is easy, even after few months, to understand it. Another good point is that it also facilitates other developers none familiar with Bootstrap to create UI components as the DSL guides them to configure the elements. The drawback is that it takes time to build the functions and sometime the Render functions aren’t straight forward. Overall I think the advantages win over the drawbacks because of the readability and the maintainability. More time will be saved then the time spent making those functions. I have created many more components for Bootstrap and you can have a look here http://kimserey.github.io/WebSharperBootstrap/ . I hope you enjoyed reading this post! As usual, if you have any comments hit me on twitter @Kimserey_Lam, thanks for reading!