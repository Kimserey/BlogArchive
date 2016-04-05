# Drag and drop UI with Sortable.js in UI.Next

Few weeks ago I covered [how to use external JS libraries with WebSharper.](http://kimsereyblog.blogspot.co.uk/2016/01/external-js-library-with-websharper-in-f.html)
I explained how we could integrate `taginput` which is a cool library that allows us to use tags in our webapp.
It was used with JQuery and I showed you how we could extended WebSharper JQuery and add `taginput` functionalities.

Today I will show you how to use another cool JS library - __Sortable__.
Sortable brings __drag - drop - sorting__ functonalities to webapps.
Also, it does not require JQuery so we will not make extensions for it.

Here is a preview of what we will be building:

![image_preview](https://raw.githubusercontent.com/Kimserey/DragAndDropSortable/master/sortable.gif)

You can find the full source code [here](https://github.com/Kimserey/DragAndDropSortable/blob/master/dragndrop/DragAndDrop.fsx).

## How does Sortable works in JS?

Sortable examples can be found [here](http://rubaxa.github.io/Sortable/).
On top of allowing us to sort elements, it also provides drag and drop functionalities which are very handy to make nice webapps.

In JS, all you need to do is create a list of elements (or a `div` containing other elements) use `Sortable`.

```
Sortable.create(myelement, { .. some options ... })
```

And that's it, `myelement` is now a sortable list. Let's see how can we use that in `WebSharper`.

## Create a link from F# to Sortable

As we saw earlier, the main function to call is `Sortable.create`.
It takes an element and some options as parameter.
Elements in WebSharper are translated with the type `Dom.Element`.
The options will be held in a record type.
We can now directly create a link:
```
[<JavaScript>]
module Sortable =
    
    [<Direct "Sortable.create($el, $options)">]
    let sortableJS (el: Dom.Element) options = X<unit>
```

We can then call `sortableJS` to make an element sortable.

```
divAttr [ on.afterRender(fun el -> sortableJS el Unchecked.defaultof<_>) ]
        [ div [ text "Aa" ]
          div [ text "Bb" ]
          div [ text "Cc" ]
          div [ text "Dd" ]
          div [ text "Ee" ] ]
```

We need to place the call to `sortableJS` in `on.afterRender` because the dom needs to be created before we call `Sortable.create`.
The `div` is now completely sortable and draggable. We can move `Aa` or `Bb` around.

__But what about the options?__

If we just need to give the ability to sort a list, we would be done.
But chances are that we need to do more, like do an action after sorting the list or drag and dropping into another list. 
And as we saw in the preview, we will be making drag and drop in between 

## Link Sortable options

Sortable has many options and you can find most of them in the [readme](https://github.com/RubaXa/Sortable/blob/master/README.md), 
We will see how we can bind few options and from there you will be able to apply the same method to use other functionalities.
Let's review in order what we are interested in so that we can focus on binding this first.

First we need to name our lists. We will name the droppable list `Workspace` and the drag and drop lists `ListA` and `ListB`.
`Workspace` will be a place to drop item in.
`ListA` will be a place to drag items from to drop into `Workspace`.
Finally `ListB` will be a place to clone items from and drop into `Workspace`.

`Sortable` has a first member called `group`.
A `group` is defined by a `name` and a `pull` action and `put` action.
`pull` defines the behaviour of pulling item from the list (drag) and put defines the behaviour of putting item into another list (drop).

Here is the implementation of `group`:
```
type Group = {
  [<Name "name">]
  Name: string
  
  [<Name "pull">]
  Pull: string
        
  [<Name "put">]
  Put: string
}
with
  static member Create name pull put =
    { Name = name
      Pull = pull |> Pull.ConvertToJSOption 
      Put  = put  |> Put.ConvertToJSOption }
    
and Pull =
| Allow
| Disallow
| Clone
with
  static member ConvertToJSOption =
    function
    | Allow    -> "true"
    | Disallow -> "false"
    | Clone    -> "clone"

and Put =
| Allow
| Disallow
| AllowList of string list
with
  static member ConvertToJSOption =
    function
    | Put.Allow          -> "true" 
    | Put.Disallow       -> "false" 
    | Put.AllowList list ->  list |> (String.concat "," >> sprintf "[%s]")
```

We need to use `Name` attribute because JS is case sensitive so we need to define the binding ourself if we capitalize our members.
Also note that I am using `string` for `Pull` and `Put` in order to respect the type expected by `Sortable`.

We can now create `group` simply by doing:
```
Group.Create "Workspace" Pull.Disallow <| Put.AllowList [ "ListA"; "ListB" ]
```

So if we create our `option` record type, it would be:

```
type Sortable = {
        [<Name "group">]
        Group: Group
        
        [<Name "sort">]
        Sort: bool
        
        [<Name "animation">]
        Animation: int
    }
        with
            static member Default =
                { Group = Group.Create "" Pull.Allow Put.Allow 
                  Sort = true
                  Animation = 150 }

            static member SetGroup group (x: Sortable) =
                { x with Group = group }

            static member AllowSort (x: Sortable) =
                { x with Sort = true }

            static member DisallowSort (x: Sortable) =
                { x with Sort = false }
            
            static member Create el (x: Sortable) =
                sortableJS el x

    and Group = {
        [<Name "name">]
        Name: string
        
        [<Name "pull">]
        Pull: string
        
        [<Name "put">]
        Put: string
    }
        with
            static member Create name pull put =
                { Name = name
                  Pull = pull |> Pull.ConvertToJSOption 
                  Put  = put  |> Put.ConvertToJSOption }
    
    and Pull =
    | Allow
    | Disallow
    | Clone
        with
            static member ConvertToJSOption =
                function
                | Allow    -> "true"
                | Disallow -> "false"
                | Clone    -> "clone"

    and Put =
    | Allow
    | Disallow
    | AllowList of string list
        with
            static member ConvertToJSOption =
                function
                | Put.Allow          -> "true" 
                | Put.Disallow       -> "false" 
                | Put.AllowList list ->  list |> (String.concat "," >> sprintf "[%s]")
```


Here we see another interesting option - `Sort`.
It configure whether the list is sortable or not.
It is useful when you want to restrict the list to only be draggable and droppable but not sortable.

`Animation` just specify the duration of the drag and drop animations.

We can then use this `Sortable` in an `on.afterRender` like so:

```
divAttr [ on.afterRender(fun el -> 
            Sortable.Default
            |> Sortable.AllowSort
            |> Sortable.SetGroup (Group.Create "listA" Pull.Allow Put.Disallow)
            |> Sortable.Create el) ]
        [ div [ text "Aa" ]
          div [ text "Bb" ]
          div [ text "Cc" ]
          div [ text "Dd" ]
          div [ text "Ee" ]
```

Next what we want is to handle all events when items are dropped or when items are sorted.

## Handling events

Specifying callbacks to be called when events happen is done from the `options` as well.
We can bind callbacks like `onAdd`, `onSort`, `onUpdate` from the `options`.
Every callback takes an `event` as parameter.
So each callback has a type of: `Event -> unit`.
This `event` contains properties which are helpful to manage our lists.
Here's the defnition of the `Event`:

```
SortableEvent = {
  [<Name "item">]
  Item: Dom.Element
        
  [<Name "from">]
  From: Dom.Element
        
  [<Name "to">]
  To: Dom.Element

  [<Name "newIndex">]
  NewIndex: int
        
  [<Name "oldIndex">]
  OldIndex: int
}
```

It's straight forward, `Item` is the item being dropped, `From` is the list from where the item is from, `To` is the list destination, `NewIndex` is the index at which the item is dropped at and `OldIndex` was the index at which the item from dragged out from.

Using this we can now define `OnAdd`:

```
[<Name "onAdd">]
OnAdd: SortableEvent-> unit
```
And we can also add a helper method on `Sortable`:

```
static member SetOnAdd onAdd (x: Sortable) =
  { x with OnAdd = onAdd }
```

With that we will be able to configure our `Sortable` record.

And we are now done! We can now create our three lists and it should work the same way as the preview!

```
[<JavaScript>]
module Client =
    open Sortable
    
    let panel title body =
        divAttr [ attr.``class`` "panel panel-default" ]
                [ divAttr [ attr.``class`` "panel-heading" ] [ text title ]
                  divAttr [ attr.``class`` "panel-body" ] [ body] ]

    let main() =
        divAttr [ attr.``class`` "row" ]
                [ divAttr [ attr.``class`` "col-sm-4" ]
                          [ panel
                                "Workspace: droppable from ListA and ListB"
                                (divAttr [ attr.style "min-height:100px;"
                                           on.afterRender(fun el -> 
                                             Sortable.Default
                                             |> Sortable.SetGroup (Group.Create "workspace" Pull.Allow <| Put.AllowList [ "listA"; "listB" ])
                                             |> Sortable.Create el) ]
                                          []) ]
                  
                  divAttr [ attr.``class`` "col-sm-4" ]
                          [ panel
                                "ListA: draggable and sortable"
                                (divAttr [ on.afterRender(fun el -> 
                                             Sortable.Default
                                             |> Sortable.AllowSort
                                             |> Sortable.SetGroup (Group.Create "listA" Pull.Allow Put.Disallow)
                                             |> Sortable.Create el) ]
                                         [ div [ text "Aa" ]
                                           div [ text "Bb" ]
                                           div [ text "Cc" ]
                                           div [ text "Dd" ]
                                           div [ text "Ee" ] ]) ]
                  
                  divAttr [ attr.``class`` "col-sm-4" ]
                          [ panel
                                "ListB: draggable and cloned"
                                (ulAttr [ on.afterRender(fun el -> 
                                              Sortable.Default
                                              |> Sortable.DisallowSort
                                              |> Sortable.SetGroup (Group.Create "listB" Pull.Clone Put.Disallow)
                                              |> Sortable.Create el) ]
                                         [ li [ text "11" ]
                                           li [ text "22" ]
                                           li [ text "33" ]
                                           li [ text "44" ]
                                           li [ text "55" ] ]) ] ]
```

You can find the full source code [here](https://github.com/Kimserey/DragAndDropSortable/blob/master/dragndrop/DragAndDrop.fsx).

# Conclusion

And that's it! That is all we need to bring this amazing library to use it with WebSharper in F#.

Today we saw how to bind JS libraries. Also we saw how we could directly use our own record types to pass it to JS functions but we also saw how those record types could be used as well to directly deal with results of JS functions.

Sortable is an amazing library which is easy to configure and allows to build interactive nice webapp. As always if you have any comments please leave it below or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). Thanks for reading!
