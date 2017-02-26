# Create a simple form engine with WebSharper.UI.Next in F#

WebSharper came out with WebSharper.Forms. It is a terse DSL to build form, I posted a tutorial on it few months ago [https://kimsereyblog.blogspot.co.uk/2016/03/create-forms-with-websharperforms.html](https://kimsereyblog.blogspot.co.uk/2016/03/create-forms-with-websharperforms.html). 
It's very powerful as the abstraction handles most of the scenarios.
Today I would like to show anothe way to create forms by building a form engine.
This post will be composed by 4 parts:
1. Define the domain
2. Implement the renderers
4. Use it
 
## 1. Define the domain

Defining a model is tricky. It needs to be both flexible enough to handle all needed scenario but it also needs to be simple enough that there aren't too many options which would make the domain messy. I will give an example later to illustrate this.

For a form engine, the domain model is composed by the elements of form and the submission behaviors.

__Form elements__

For this example we will just implement the `input` and `input area`. Implementing the rest of the control will just be a repetition of those steps.
We start by defining the model as such:

```
type FormElement =
| TextInput of key: string 
                * title: string
                * placeholder: string
                * defaultValue: string option
| TextArea of key: string 
                * title: string
                * numberOfLines: int
                * defaultValue: string option
```

__Submission behaviors__

For the `submission behaviors`, we will be allowing json Ajax submit or simple multiform post data.
So we can define the behaviors as such:

```
type FormSubmitter =
| AjaxPost of postHref: string
                * redirectOnSuccessHref: string
                * title: string 

| AjaxPostFormData of postHref: string
                        * redirectOnSuccessHref: string
                        * title: string
```

__Form__

Now that we have both we can compose it into a form:

```
type Form =
    { Key: string
      Elements: FormElement list
      Submitter: FormSubmitter }
```

## 2. Implement the renderers

The role of the renderer is, given a model, to render the layout and build a doc.

So we start by the top level render form:

```
let private displayList (list: string) =
    list.Split([| '\n' |]) 
    |> Array.map (fun txt -> Doc.Concat [ text txt; br [] :> Doc ])

let private renderError error =
    match error with 
    | None
    | Some "" -> Doc.Empty 
    | Some err ->
        pAttr 
            [ attr.``class`` "alert alert-danger" ] 
            (displayList err) :> Doc
let renderForm (form: Form) =
    let values = 
        ListModel.Create 
            (fun (k, _) -> k) 
            (form.Elements |> List.map (fun e -> e, ""))
    
    let error = Var.Create ""

    formAttr 
        [ attr.id form.Key ]
        [ error.View |> Doc.BindView (fun err -> )
          renderElements values form.Elements
          renderSubmitter form.Key values error form.Submitter  ]
```

In order to save all the aggregate all the values before submitting it, we use a `ListModel` which we will `lens into` to modify the specific data.

_If you never seen lenses, I recommend you to read my previous post on ListModel lenses [https://kimsereyblog.blogspot.co.uk/2016/03/var-view-lens-listmodel-in-uinext.html](https://kimsereyblog.blogspot.co.uk/2016/03/var-view-lens-listmodel-in-uinext.html)._

We then define `renderElements`:

```
    let private renderElements (values: ListModel<FormElement, (FormElement * ValueState * string)>) (elements: FormElement list) =
        let lensIntoValue = values.LensInto (fun (_, v) -> v) (fun (e, _) v -> e, v)
       
        values.View
        |> Doc.BindSeqCachedViewBy (fun (k, _) -> k) (fun el view ->
            let value = lensIntoValue el
            let initValue df =
                match df with
                | Some defaultValue -> value.Set defaultValue
                | None -> ()

            match el with
            | TextInput (k, t, ph, df) ->
                initValue df

                divAttr
                    [ attr.``class`` "form-group" ]
                    [ labelAttr [ attr.``for`` k ] [ text t ]
                      
                      Doc.Input 
                        [ attr.id k
                          attr.``type`` "text"
                          attr.``class`` "form-control"
                          attr.placeholder ph ] 
                        value ] :> Doc
                      
            | TextArea (k, t, n, df) ->
                initValue df

                divAttr
                    [ attr.``class`` "form-group" ]
                    [ labelAttr [ attr.``for`` k ] [ text t ]
                      Doc.InputArea 
                        [ attr.id k
                          attr.rows (string n)
                          attr.``class`` "form-control" ] 
                        (lensIntoValue el) ] :> Doc
```

As said earlier, we lense into the value to get a `IRef<_>` which can then be passed to WebSharper UI.Next client `Doc.InputX` functions.

Next we can implement `renderSubmitter` which renders the submitters:

```
let private renderSubmitter key (values: ListModel<_, _>) (error: IRef<_>) submitter =
    match submitter with
    | AjaxPost (href, redirect, title) ->
        Doc.Button title 
            [ attr.``class`` "btn btn-primary btn-block" ] 
            (fun () -> 
                async {
                    let! result = boxValuesJson values.Value |> AjaxHelper.postJson href

                    match result with
                    | AjaxHelper.Success res -> JS.Window.Location.Href <- redirect
                    | AjaxHelper.NotFound -> ()
                    | AjaxHelper.Error msg -> error.Value <- Some msg
                }
                |> Async.Ignore
                |> Async.StartImmediate)

    | AjaxPostFormData (href, redirect, title) ->
        Doc.Button title 
            [ attr.``class`` "btn btn-primary btn-block" ] 
            (fun () -> 
                async {
                    let! result = boxValuesFormData values.Value |> AjaxHelper.postFormData href

                    match result with
                    | AjaxHelper.Success res -> JS.Window.Location.Href <- redirect
                    | AjaxHelper.NotFound -> ()
                    | AjaxHelper.Error msg -> error.Value <- Some msg
                }
                |> Async.Ignore
                |> Async.StartImmediate)
```

_The AjaxHelper is a module with helper functions to execute ajax calls._
Notice that we create a DU of specific action. We defined AjaxPost and MultidataPost. This choice related to what I said in 1) "flexible enough to handle all needed scenario but it also needs to be simple enough that there aren't too many options which would make the domain messy".
We could had a function pass as submitter behavior which would allow infinite possibilities but this would cause the domain to be harder to understand. A newcomer or even my future me will most likely be confused by what to pass in this function. Therefore choosing to express the possible actions explicitly with a DU is much better than leaving infinite options.

We are now able to render the whole form.

## 3. Use it

So we have a model, we defined the renderer for that model and lastely we defined how to submit the data. Thanks to this we can now create form very quickly and easily by instiating the model and passing it to the render function.

Code 

Image

# Conclusion

Today we saw how we could create a form engine with a simple domain which allows quick creation of forms in WebSharper.UI.Next. Hope you liked this post. If you have any question leave it here or hit me on Twitter [@Kimserey_Lam](). See you next time!

# Other posts you will like!
