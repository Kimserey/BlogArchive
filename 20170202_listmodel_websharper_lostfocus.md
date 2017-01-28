# How to avoid input lost focus with ListModel WebSharper F#

Few months ago, I explained [how ListModel worked](https://kimsereyblog.blogspot.co.uk/2016/03/var-view-lens-listmodel-in-uinext.html). Today I would like to share a recurring issue that I used to have - __lost of focus on input every time the ListModel values change__. There's an easy solution to that which I will demonstrate by first showing the initial code and explaining what is going on, why the focus is lost, then I will explain how we can work around it.

This post will be composed by two parts:

```
 1. Why the inputs lose focus?
 2. How to prevent it
```

_I thought about sharing this when I saw that someone else has had the same issue - [http://try.websharper.com/cache/0000Bj](http://try.websharper.com/cache/0000Bj)._

## 1. Why the inputs lose focus?

The code is the following:

```
[<JavaScript>]
module Lensing =

    let aliases = 
        ListModel.Create id [ "Bill"; "Joe" ]
    let lensIntoAlias aliasKey = 
        aliases.LensInto id (fun a n -> n) aliasKey
    let Main =
        div [
            aliases.View
            |> Doc.BindSeqCached (fun (aliasKey: string) -> Doc.Input [] (lensIntoAlias aliasKey))
            
            aliases.View
            |> Doc.BindSeqCached (fun (aliasKey: string) -> div [ text aliasKey ])
                
        ]
        |> Doc.RunById "main"
```

If you try this [http://try.websharper.com/embed/Lamk/0000C3](http://try.websharper.com/embed/Lamk/0000C3), you will see that the list gets updated but the input focus is lost after each changes.

The problem comes from the fact that the form itself is observing the list changes. 
If we look at how the form is rendered, it is rendered in the `View callback` therefore every time we change the ListModel the whole form is re-rendered and since the old `dom` is removed, we lose focus on the input.

```
aliases.View
|> Doc.BindSeqCached (fun (aliasKey: string) -> Doc.Input [] (lensIntoAlias aliasKey)) // <<= This input is re-rendered every time aliases ListModel changes
```

So what can we do about it?

## 2. How to prevent it
### 2.1 Number of elements doesn't change

The first problem is that the `Key` used for the lens __is__ the value in that example. So let's fix this by giving each alias a key by introducing a type `Alias`.

```
type Alias = { Key: int; Value: string }

let aliases = 
    ListModel.Create (fun a -> a.Key) [ { Key = 1; Value = "Bill" }; { Key = 2; Value = "Joe" } ]
let lensIntoAlias aliasKey = 
    aliases.LensInto (fun a -> a.Value) (fun a n -> { a with Value = n }) aliasKey
    
```

If the number of elements doesn't change, we actually don't need to observe the list. We can take its initial value and render the form. Like that the Dom will not be deleted each time.

```    
type Alias = { Key: int; Value: string }

let aliases = 
    ListModel.Create (fun a -> a.Key) [ { Key = 1; Value = "Bill" }; { Key = 2; Value = "Joe" } ]
let lensIntoAlias aliasKey = 
    aliases.LensInto (fun a -> a.Value) (fun a n -> { a with Value = n }) aliasKey
    
let Main =
    div 
        [
            aliases.Value
            |> Seq.map (fun al -> Doc.Input [] (lensIntoAlias al.Key))
            |> Seq.cast
            |> Doc.Concat
                
            aliases.View
            |> Doc.BindSeqCached (fun al -> div [ text al.Value ])
        ]
    |> Doc.RunById "main"
```

### 2.2 Number of elements needs to change

If we need to observe the list changes, observe when elements are added or removed, the form will have to be re-rendered and we will have to lose focus.
To work around that, we can use a `Snapshot` combined with a Update button.

```
View.SnapshotOn aliases.Value trigger.View
```

`Snapshot` are used with a combined `Var`, I call it a `trigger`. It is just a `Var<unit>` which, when set, will trigger the refresh of the view.

So here's how we use it:

```
let trigger =
    Var.Create ()

let Main =
    div 
        [
            Doc.Button 
                "Add alias" 
                [ attr.style "display: block" ]
                (fun() -> 
                    aliases.Add({ Key = aliases.Length + 1; Value = "New" })
                    // trigger update here
                    trigger.Value <- ())
            
            aliases.View
            |> View.SnapshotOn aliases.Value trigger.View
            |> Doc.BindSeqCached (fun al -> Doc.Input [] (lensIntoAlias al.Key))
                
            aliases.View
            |> Doc.BindSeqCached (fun al -> div [ text al.Value ])
        ]
    |> Doc.RunById "main"
```

So when we __add__ a new alias, we trigger an update of the form. __This makes the form only render when the user click on Add.__

# Conclusion

Today we saw how we could work around the problem of losing focus in input when ListModle gets updated. Hope you liked this post, if you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Other posts you will like!

- Authentication JWT token for WebSharper sitelets - [https://kimsereyblog.blogspot.co.uk/2017/01/authentication-for-websharper-sitelet.html](https://kimsereyblog.blogspot.co.uk/2017/01/authentication-for-websharper-sitelet.html)
- Setup logs for your WebSharper webapp - [https://kimsereyblog.blogspot.co.uk/2016/12/output-logs-in-console-file-and-live.html](https://kimsereyblog.blogspot.co.uk/2016/12/output-logs-in-console-file-and-live.html)
- Understand sqlite with Xamarin - [https://kimsereyblog.blogspot.co.uk/2017/01/get-started-with-sqlite-in-from.html](https://kimsereyblog.blogspot.co.uk/2017/01/get-started-with-sqlite-in-from.html)
- Understand Var, View and Lens in WebSharper - [https://kimsereyblog.blogspot.co.uk/2016/03/var-view-lens-listmodel-in-uinext.html](https://kimsereyblog.blogspot.co.uk/2016/03/var-view-lens-listmodel-in-uinext.html)
- Bring i18n to your WebSharper webapp - [https://kimsereyblog.blogspot.co.uk/2016/08/bring-internationalization-i18n-to-your.html](https://kimsereyblog.blogspot.co.uk/2016/08/bring-internationalization-i18n-to-your.html)
- Create HTML components in WebSharper - [https://kimsereyblog.blogspot.co.uk/2016/08/create-html-componants-for-your.html](https://kimsereyblog.blogspot.co.uk/2016/08/create-html-componants-for-your.html)

# Support me! 

[Support me by visting my website](https://www.kimsereylam.com). Thank you!

[Support me by downloading my app BASKEE](https://www.kimsereylam.com/baskee). Thank you!

![baskee](https://raw.githubusercontent.com/Kimserey/kimserey.github.io/master/img/readme/baskee_screenshots.png)

[Support me by downloading my app EXPENSE KING](https://www.kimsereylam.com/expenseking). Thank you!

![expense king](https://raw.githubusercontent.com/Kimserey/kimserey.github.io/master/img/readme/expenseking_screenshots.png)

[Support me by downloading my app RECIPE KEEPER](https://www.kimsereylam.com/recipekeeper). Thank you!

![recipe keeper](https://raw.githubusercontent.com/Kimserey/kimserey.github.io/master/img/readme/recipekeeper_screenshots.png)
