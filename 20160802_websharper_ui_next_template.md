# Create reusable HTML componants for your WebSharper webapp UI Next template

WebSharper.UI.Next comes with a simple template engine which can be used to build `doc` elements.
It is built using a F# typeprovider therefore gives typesafety for templating.

_If you never used WebSharper or WebSharper.UI.Next before, I published a tutorial few months ago on how WebSharper works and how you can use it to create SPA's - [https://kimsereyblog.blogspot.co.uk/2015/08/single-page-app-with-websharper-uinext.html](https://kimsereyblog.blogspot.co.uk/2015/08/single-page-app-with-websharper-uinext.html)_

WebSharper official documentation can be found here [https://github.com/intellifactory/websharper.ui.next/blob/master/docs/Templates.md](https://github.com/intellifactory/websharper.ui.next/blob/master/docs/Templates.md).

In this post I will explain some of the functionalities of WebSharper.UI.Next template and give specific examples to showcase how they can be used. 
This post will be compose by five parts:

```
 1. Get started with templates
 2. Template holes
 3. Sub templates
 4. On click event
 5. Value bindings
```

__All the code here can be found on GitHub - [https://github.com/Kimserey/WSTemplate/blob/master/WSTemplate/Client.fs](https://github.com/Kimserey/WSTemplate/blob/master/WSTemplate/Client.fs)__

## 1. Get started with templates

Let's start by a hello world template.

Create a `hello.html` file containing the following div:
```
<!-- hello.html -->
<div>Hello world</div>
```

Then create a type which will load the template and __provide a type__ for that template.

_I suppose that's why they called it typeprovider, it provides a type for a resource given, here html resource._

```
open WebSharper.UI.Next

type Hello = Templating.Template<"hello.html">
```

The `Hello` type can then be used anywhere to create a `div` containing `Hello world`.

```
let main =
    Hello.Doc()
    |> Doc.RunById "main"
```

This code will produce a `hello world` and place it in the html element of id `main`. 
From here we can already see how templates can be reused to quickly compose and create blocks of elements.
But static templates like this `hello world` have very limited usage, `UI.Next` templates provide much more functionalities. 
It also allows to specify special tokens which can be used to modify the template.

One of these tokens are the `holes` which we are going to view next.

## 2. Template holes

When you define a template, the whole `html` page becomes the template and is rendered.
`Holes` are used to specify places where you need to insert extra `doc`'s or `elt`'s.
They can be defined using the attributes `data-hole` or `data-replace`.

### 2.1 data-hole

`data-hole` can be placed on elements where you want to provide your own elements.

For example, if you have a `div` which represents a list and wish to create a reusable componant for it, you could do this:

```
<!--list.html-->
<ul data-hole="Links">
</ul>
``` 

Using this as template, you can then define the following:

```
type List = Templating.Template<"list.html">
```

```
let main =
    List.Doc(Links = [ 
        li [ text "Hello 1" ]
        li [ text "Hello 2" ] 
    ]) |> Doc.RunById "main"
```

Here we can observe that the typeprovider template added the `Links` as argument of the `Doc()` function.
__Using the template, we get typesafety__.

### 2.2 data-replace

`data-replace` can be used when you want to replace the whole element instead of the content only.
A typical example is when there is no parent to the element you need to replace in the current template.

```
<!--description.html-->
<h1>Some title</h1>
<div data-replace="Content"></div>
```

```
type Description = Templating.Template<"templates\description.html">
```

```
let main =
    Description.Doc(Content = [ 
        p [ text "Something..." ]
    ]) |> Doc.RunById "main"
```

## 3. Sub templates

Sub templates are used to create reusable child components.
A typical example would be a list-group with two child list-item, a normal and an active list-item.
Sub templates can be defined usng `data-children-template` or `data-template`.

### 3.1 data-children-template

`data-children-template` means that the content of the elements will be available as sub template.

```
<!--list-group.html-->
<div class="list-group">
    <a href="#" class="list-group-item" data-hole="FirstBody" data-children-template="Item">
        <h4 class="list-group-item-heading">${Title}</h4>
        <p class="list-group-item-text"></p>
    </a>
    <a href="#" class="list-group-item" data-hole="SecondBody"></a>
</div>
```

Here we define a template composed by the child elements given by the first anchor tag.
`Item` template can then be used in `SecondBody` as well.

```
type ListGroup = Templating.Template<"list-group.html">
```

```
let main =
    ListGroup.Doc(
        FirstBody = [ ListGroup.Item.Doc(Title = "First") ],
        SecondBody = [ ListGroup.Item.Doc(Title = "Second") ]
    ) |> Doc.RunById "main"
```

### 3.2 data-template

And alternative way to define sub template is `data-template`.
`data-template` means that the element itself plus the child elements will be available as sub template.

```
<!--list-group-2.html-->
<div class="list-group" data-hole="List">
    <a href="#" class="list-group-item" data-template="ListItem">
        <div>Some content</div>
    </a>
    <a href="#" class="list-group-item active" data-template="ActiveListItem">
        <div>Some active content</div>
    </a>
</div>
```

For example here we defined two templates `ListItem` and `ActiveListItem` which will produce difference `<a>`.
We also defined a hole `List` where we will insert the list items.

```
type ListGroup2 = Templating.Template<"templates\list-group-2.html">
```

```
ListGroup2.Doc(
    [
        ListGroup2.ListItem.Doc()
        ListGroup2.ListItem.Doc()
        ListGroup2.ActiveListItem.Doc()
    ]
) |> Doc.RunById "main"
```

## 4. On click event

On click events are handled using the attribute `data-click-event`.
It can be placed on any element to handle click events.

```
<button class="btn btn-block btn-lg btn-success" data-event-click="Send">Send</button>
```

```
Button.Doc(
    Send = fun el ev -> 
        // do something here
        ()
) |> Doc.RunById "main"
```

The `data-event-click` provides a typesafe way to define callbacks. The `Send` function is called with the `Dom.Element` and the `Dom.Event`.

## 5. Value bindings

Lastely string can be bound to the templae via simple markups.
Static string can be inserted using `${Value}` and dynamic string (reactive variable views) can be inserted using `$!{Value}`. 

_For more details on Views, I posted a more in depth tutorial about `Views` - [https://kimsereyblog.blogspot.co.uk/2016/03/var-view-lens-listmodel-in-uinext.html](https://kimsereyblog.blogspot.co.uk/2016/03/var-view-lens-listmodel-in-uinext.html)_

### 5.1 ${Value}

`${Value}` is used to pass string values to the template.
It can be used on attribute values or text content.

```
<!--value.html-->
<a href="${Href}" class="list-group-item ${ExtraCls}">
    <h4 class="list-group-item-heading">${Title}</h4>
    <p class="list-group-item-text">${Text}</p>
</a>
```

For example, here we use it to set the `href` attribute and to add an extra css class.
We also use it to set the title and text content.

```
type Value = Templating.Template<"templates\\value.html">
```

```
Value.Doc(
    Href = "#",
    ExtraCls = "test",
    Title = "Title",
    Text = "Content"
) |> Doc.RunById "main"
```

### 5.2 $!{Value}

`$!{Value}` is used to pass reactive Views to the template.

```
<!--value-2.html-->
<div>$!{Text}</div>
<button data-event-click="OnClick">Click</button>
```

```
type Value2 = Templating.Template<"templates\\value-2.html">
```

```
let text = Var.Create "Not clicked"

Value2.Doc(
    Text = text.View,
    OnClick = fun _ _ -> Var.Set text "Clicked!"
) |> Doc.RunById "main"
```

`Text` is bound to a reactive View, when the button is clicked, the `Var` is set to `Clicked!` which propagate the changes to the `View` and to the html doc.

## Conclusion

There are times where defining HTML templates is quicker than composing elements with `WebSharper.UI.Next.Html` combinators.
WebSharper provides both solutions where both are typesafe.
UI.Next template is a powerful tool with a small amount of features, it handles majority of the scenarios.
Hope you enjoyed reading this post as much as I enjoyed writing it.
As always, if you have any comments leave it here or hit me on Twitter [https://twitter.com/Kimserey_Lam](https://twitter.com/Kimserey_Lam).

# More posts you will like

If you like reading about WebSharper, I published other extremely interesting topics:

- Understand WebSharper `Var`, `View`, `Lens`: [https://kimsereyblog.blogspot.co.uk/2016/03/var-view-lens-listmodel-in-uinext.html](https://kimsereyblog.blogspot.co.uk/2016/03/var-view-lens-listmodel-in-uinext.html)
- Prototyping WebSharper webapp with `Warp`: [https://kimsereyblog.blogspot.co.uk/2016/03/prototyping-web-app-made-easy-with.html](https://kimsereyblog.blogspot.co.uk/2016/03/prototyping-web-app-made-easy-with.html)
- Create an animated menu with WebSharper: [https://kimsereyblog.blogspot.co.uk/2016/03/create-animated-menu-with.html](https://kimsereyblog.blogspot.co.uk/2016/03/create-animated-menu-with.html)
- Create a SPA with WebSharper and WebSharper.UI.Next: [https://kimsereyblog.blogspot.co.uk/2015/08/single-page-app-with-websharper-uinext.html](https://kimsereyblog.blogspot.co.uk/2015/08/single-page-app-with-websharper-uinext.html)
