# Var, View, Lens, ListModel in UI.Next

Last week I needed to make a __two way binding for a record with nested lists__.
I needed to observe any changes on a record which also contained nested lists.
This changes included member changes but also list changes like adding and removing items.

It took me roughly a week to come out with a solution and it didn't come straight away.
It was more of a battle and I iterated multiple time to get to the final stage.
I started with one solution then had a [conversation on WebSharper forum](http://websharper.com/question/81323/what-would-be-the-best-way-to-make-a-two-way-binding-on-a-record-from-a-list-of-list) with [@tarmil_](https://twitter.com/Tarmil_) and [@inchester23](https://twitter.com/inchester) and came out better solutions.

I really think that the process is as beneficial as the solution so today I will like to take another approach for this blog post.
Instead of walking you through the final solution, I will describe the steps to the final solution.
And as usual, [the code is available on GitHub](https://github.com/Kimserey/VarViewTest/tree/master/VarViewTest).

Here's how I interated:
 1. The wrong way - a mutable record - [link to code](https://github.com/Kimserey/VarViewTest/blob/master/VarViewTest/Book_Sample_v1.fsx)
 2. The right way - lensing into members - [link to code](https://github.com/Kimserey/VarViewTest/blob/master/VarViewTest/Book_Sample_v2_Lens.fsx)
 3. The optimised way - optimising with ListModel - [link to code](https://github.com/Kimserey/VarViewTest/blob/master/VarViewTest/Book_Sample_v3_ListModel.fsx)

The record for which I wanted to observe every members was the following:
```
type Book = {
    Title: string
    Pages: Page list
}

and Page = {
    Number: int
    Content: string
    Comments: Comment list
}

and Comment = {
    Number: int
    Content: string
}
```

A `Book` can have many `Page`s and each `Page` can have many `Comment`s.

## The wrong way - a mutable record

It's quite trivial to observe variables with `var` and `view`.
If you are not familiar with `UI.Next`, have a look at my previous blog post on [how to make a SPA with WebSharper](http://kimsereyblog.blogspot.co.uk/2015/08/single-page-app-with-websharper-uinext.html).

__But how would you observe members of a record?__

Well the first solution which came out was to make a __full mutable record__.
So using the `Book`, we create a `ReactiveBook` with all the members as `Var<_>`.

```
    type Book = {
        Title: string
        Pages: Page list
    }
    and Page = {
        Number: int
        Content: string
        Comments: Comment list
    }
    and Comment = {
        Number: int
        Content: string
    }

    type ReactiveBook = {
        Title: Var<string>
        Pages: Var<ReactivePage list>
    }
    and ReactivePage = {
        Number: Var<int>
        Content: Var<string>
        Comments: Var<ReactiveComment list>
    }
    and ReactiveComment = {
        Number: Var<int>
        Content: Var<string>
    }
```

Doing this we have a record where we can observe every member.
First we need to combine all the views to make one single view for the `ReactiveBook`.

```
type ReactiveComment with
    static member View comment: View<Comment> =
        View.Const (fun n c -> 
            { Number = n
              Content = c })
        <*> comment.Number.View
        <*> comment.Content.View

type ReactivePage with
    static member View (page: ReactivePage): View<Page> =
        View.Const (fun n c com-> 
            { Number = n
              Content = c
              Comments = com |> Seq.toList })
        <*> page.Number.View
        <*> page.Content.View
        <*> (page.Comments.View
                |> View.Map (fun comments -> 
                    comments 
                    |> List.map ReactiveComment.View 
                    |> View.Sequence) 
                |> View.Join)

type ReactiveBook with
    static member View book: View<Book> =
        View.Const (fun t p -> 
            { Title = t
              Pages = p |> Seq.toList })
        <*> book.Title.View
        <*> (book.Pages.View 
                |> View.Map (fun pages -> 
                    pages 
                    |> List.map ReactivePage.View 
                    |> View.Sequence) 
                |> View.Join)
```

This way we can map over a `ReactiveBook.View` or use `Doc.BindView` to render it.

```
let rvBook =
    Var.Create { Title = Var.Create "New book"
                 Pages = Var.Create [] }

rvBook
|> ReactiveBook.View
|> Doc.BindView Book.Render
```

And like that when we change anything in `rvBook`, it will be reflected in the doc.

__What is wrong with that?__

Well although it works, what I did here is that I transformed a record to a totally mutable record.
This feels kind of wrong doesn't it?

What I wanted from the beginning is to be able to create a `Var.Create Book` and just use that directly,
I didn't want to have to bother with a `ReactiveBook`.

So I requested for some help and [@tarmil_](https://twitter.com/Tarmil_) pointed to me that there was a set functions exactly for my needs and that was the `Lenses`.

>This is exactly the kind of situation you would use lensing for. The type IRef<'T> is an abstract class that is implemented by Var<'T>, but also returned by the Lens method which creates a bidirectional binding into another IRef<'T>

>__[@tarmil_](https://twitter.com/Tarmil_)__

So let's take a look at `Lenses`.

## The right way - lensing into members

### What are lenses?

We already know that it is easy to observe variables.

```
let txt =
    Var.Create ""

let doc =
    txt.View
    |> Doc.BindView (fun t -> text t)
```

We create a `txt` reactive variable and bind it to a doc.
We can set the `txt` by using `Var.Set`.

```
Var.Set txt "new text!"
```

By doing that, the changes are directly propagated to the doc.
If we want to react to changes in records, we can do the same:

```
type MyRecord = { Content: string }

let r =
    Var.Create { Content = "" }
```

Because record are immutable, if you want to react to changes in the `Content` member, you need to recreate the whole record.

```
Var.Set r { Content = "Hello world" }
```

But if you remember, our `Book` can have multiple `Page`s and each one can have `Comment`s.
Imagine what we would need to do if we wanted to change the content of a `Comment`.
Lucky us, we have `Lens`.

`Lenses` in WebSharper allow us to target a particular member and extract a `IRef<_>` out of it.
`IRef<_>` is the interface implemented by `Var` and we can use it with a set of function to create inputs like `Doc.Input`.

The signature of `Lens` on `Var` is:

```
IRef<'a>.Lens :: ('a -> 'b) -> ('a -> 'b -> 'a) -> IRef<'b>
```

The first function `'a -> 'b` is used to select the member which we want to lens.
And the second function `'a -> 'b -> 'a` is used to update the current record of type `'a` with the value set of type `'b`. The `Lens` returns a reactive variable of `'b` which is the type of the member we lens into.

Since a `IRef<_>` is returned, we can lens another level and this will also return another `IRef<_>` and we can continue indefinitly like that.

So if we wanted to have a reactive variable on `Comment.Content`, from the `Book` we can lens into a particular `Page` then lens into a particular `Comment` and get out a `IRef<string>`.

 ### Change our model
 
 Now we can throw away the `ReactiveBook` and build some `Lenses` helpers using the `Lens` on `Book`!
 
 ```
 type Book = {
        Title: string
        Pages: Page list
} with
    static member LensTitle (v: IRef<Book>) : IRef<string> =
        v.Lens 
            (fun b -> b.Title) 
            (fun b t -> 
                { b with Title = t })

    static member LensPages (v: IRef<Book>) : IRef<Page list> =
        v.Lens 
            (fun b -> b.Pages) 
            (fun b p -> 
                { b with Pages = p })
        
    static member LensPage n (v: IRef<Book>) : IRef<Page> =
        v.Lens
            (fun b -> 
                b.Pages 
                |> List.find (fun p -> p.Number = n))
            (fun b p -> 
                { b with 
                    Pages = 
                        b.Pages 
                        |> List.map (fun p' -> if p'.Number = n then p else p') })

and Page = {
    Number: int
    Content: string
    Comments: Comment list
} with
    static member LensNumber (v: IRef<Page>) : IRef<int> =
        v.Lens 
            (fun c -> c.Number) 
            (fun c n -> 
                { c with Number = n })

    static member LensContent (v: IRef<Page>) : IRef<string> =
        v.Lens 
            (fun c -> c.Content) 
            (fun c cont -> 
                { c with Content = cont })    
        
    static member LensComments (v: IRef<Page>) : IRef<Comment list> =
        v.Lens 
            (fun c -> c.Comments) 
            (fun p c -> 
                { p with Comments = c })
        
    static member LensComment n (v: IRef<Page>) : IRef<Comment> =
        v.Lens 
            (fun p -> 
                p.Comments 
                |> List.find (fun p -> p.Number = n)) 
            (fun c com -> 
                { c with
                    Comments = 
                        c.Comments 
                        |> List.map (fun c' -> if c'.Number = n then com else c') })

and Comment = {
    Number: int
    Content: string
} with
    static member LensNumber (v: IRef<Comment>) : IRef<int> =
        v.Lens 
            (fun c -> c.Number) 
            (fun c n -> { c with Number = n })

    static member LensContent (v: IRef<Comment>) : IRef<string> =
        v.Lens 
            (fun c -> c.Content)
            (fun c cont -> { c with Content = cont })    
 ```

And we can also throw away all the methods to create a `view`. Since we only deal with `book` __we now have successfuly reduced the number `Var`s to only one__.
We started with a copy of the original record with all the members being `Var` and we now end up with only one `Var`.
We eliminated a record full of Vars!

## The optimised way - optimising with ListModel

We now have a bidirectional binding with our `Book` type. But we are dealing with `list` and when anything is changed, we recreate the whole `Book`.

[@inchester23](https://twitter.com/inchester) pointed to me that to optimise that I could make use of `ListModel`.

>You could define a ListModel of books then lens all the way down to the content of a comment. So using an immutable model your code might look like the following: http://try.websharper.com/snippet/qwe2/00007D. But there is an issue here: since our model is immutable, we have to copy and update the whole thing even if we just change one comment. So, while this clean and pretty, if you have a huge amounts of books and pages and comments this will get pretty slow. What i would do in that case is to define pages and comments to be ListModel<int, Page> and ListModel<int, Comment>

>__[@inchester23](https://twitter.com/inchester)__

### What are ListModel?

[ListModel](https://github.com/intellifactory/websharper.ui.next/blob/master/WebSharper.UI.Next/Models.fs#L200) are used when we deal with reactive list. Instead of using `Var<string list>`, we can use `ListModel<string, string>`.

To create a `ListModel`, we use `ListModel.Create` which has a type:

```
ListModel.Create :: 'a -> 'key -> seq<'a> -> ListModel<'key, 'a>
```

The first type represents the `key` and the second represents the `model`.
The `key` is used to target a particular instance in the list.

`ListModel`s are cool because they offer a set of helpful functions like `Add`, `Remove`, `RemoveBy` and most importantly when observing them, we can use `MapSeqCachedBy` or `Doc.BindSeqCached` which are optimised to do some clever caching for the elements which have not changed yet.
Also, `ListModel` has a special lens `LensInto` which allows us to get our a `IRef<_>` from a member of an element of the list.

### Change our model

With `ListModel` we endup with a even simpler model.
Let's change the list to `ListModel`.

```
type Book = {
    Title: string
    Pages: ListModel<int, Page>
} with
    static member LensTitle (v: IRef<Book>) : IRef<string> =
        v.Lens
            (fun b -> b.Title)
            (fun b t -> { b with Title = t })

and Page = {
    Number: int
    Content: string
    Comments: ListModel<int, Comment>
} with
    static member LensIntoContent key (pages: ListModel<int, Page>) : IRef<string> =
        pages.LensInto
            (fun p -> p.Content) 
            (fun p c -> { p with Content = c })
            key

and Comment = {
    Number: int
    Content: string
} with
    static member LensIntoContent key (comments: ListModel<int, Comment>) : IRef<string> =
        comments.LensInto
            (fun c -> c.Content)
            (fun c c' -> { c with Content = c' })
            key
```

With that we eliminated the extra `Lens` functions that we needed for our `list` types because we can directly use the `Lens` and `LensInto` functions exposed by `ListModel`. On top of that we can use `Doc.BindSeqCached` when rendering the list and get better performance.

Wonderful! We now have a model that can be observed on any members including the lists.

## Conclusion

When I started programming, I used to be stressed over people reviewing my code. But after I passed that mental barrier, I rapidly understood that review from trusted entities is extremely beneficial for your software but even more beneficial for yourself.

We started with an idea and a bad implementation. After few rounds of conversation with the guys working on `WebSharper`, we ended up with a very nice solution and we ended up with understanding much better some functionalities of `WebSharper`.

We now know that we should restrict the number of `Var` that we use. Then when dealing with `list` we can use `ListModel`. Finally we know that we can use `Lenses` to observe members of records. Hope you enjoyed this post, if you have any comments, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). Thanks for reading!
