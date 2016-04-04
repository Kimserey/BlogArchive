# Drag and drop UI with Sortable.js in UI.Next

Few weeks ago I covered how to use external JS libraries with WebSharper.
I explained how we could integrate `taginput` which is a cool library that allows us to use tags in our webapp.
It was used with JQuery and I showed you how to use it by making extensions on WebSharper JQuery.
Today I will introduce another cool JS library - __Sortable__.
Sortable brings drag, drop and sorting functonalities to webapps.
Also, it does not require JQuery so we will not make extensions for it.

Here is a preview of what we will be building:

![image_preview](Sortabl://raw.githubusercontent.com/Kimserey/DragAndDropSortable/master/sortable.gif)

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
divAttr [ on.afterRender(fun el -> 
            Sortable.Default
            |> Sortable.AllowSort
            |> Sortable.Create el) ]
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

Sortable has many options, we see will how we can bind few options and from there you will be able to apply the same method to use other functionalities.

We can see all the available options here. Let s review in order what we are interested in so that we can focus on binding this first.

Group


Name


Pull


Put

This option will define the behaviour of the list by specifying if the elements can be pulled out of the list or whether other can put elements into the list.

We represents pull in the following way

And put




Sort

Specify whether the list can be sorted or not.

OnAdd


OnAdd is triggered when an item is added.

OnSort


OnSort is triggered when the list is sorted. Take note that OnSort is also called when an item is added.

OnAdd and OnSort take callbacks in their definition.


When the callback is called it is passed an event which contains info about the list.

The interesting information are


- `NewIndex


OldIndex


From


The origin list


To


The destination list


Item


The item added

Now one issue is that JS is case sensitive. Therefore we can't directly use record type with first lettet capital members.

To make a manual binding, we can use NameAttribute.

```
example
```

# Conclusion

And that's it! That is all we need to bring this amazing library to use it with WebSharper in F#.

Today we saw how to bind JS libraries. Also we saw how we could directly use our own record types to pass it to JS functions but we also saw how those record types could be used as well to directly deal with results of JS functions.

Sortable is an amazing library which is easy to configure and allows to build interactive nice webapp. As always if you have any comments please leave it below or hit me on Twitter @Kimserey_Lam. Thanks for reading!
