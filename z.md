# Create a simple form engine with WebSharper.UI.Next in F#

WebSharper came out with WebSharper.Forms. It is a terse DSL to build form (link), I posted a tutorial on it few months ago (link). 
It's very powerful as the abstraction handles most of the scenarios.
Today I would like to show anothe way to create forms by building a form engine.
This post will be composed by 4 parts:
1. Define the domain
2. Implement the renderers
3. Implement the submit behavior
4. Use it
 
## 1. Define the domain

Defining a model is tricky. It needs to be both flexible enough to handle all needed scenario but it also needs to be simple enough that there aren't too many options which would make the domain messy. I will give an example later to illustrate this.

For a form engine, the domain model is composed by the elements of form and the submission behaviors.

The form elements

For this example we will just implement the input, input area and the select input.
So we can define the model as such:

Code

The submission behaviors

For the submission behaviors, we will be allowing json Ajax submit or simple multiform encoded.
So we can define the behaviors as such:

Code

Now that we have both we can compose it into a form:

Code

## 2. Implement the renderers

The role of the renderer is, given a model, to render the layout and build a doc.

So we start by the top level render form

Code

We then move to render element

Code

As you can see we now end up rendering the whole form.

## 3. Submitter behavior

In order to handle the form values, we use a ListModel which will store all values in string.

 What we need to do next is perform and action once the form is submitted. We call that the submitter behavior. It is either an Ajax post or a multidata encoded post.

Code

Notice that we create a DU of specific action. We defined AjaxPost and MultidataPost. This choice related to what I said in 1) "flexible enough to handle all needed scenario but it also needs to be simple enough that there aren't too many options which would make the domain messy".
We could had a function pass as submitter behavior which would allow infinite possibilities but this would cause the domain to be harder to understand. A newcomer or even my future me will most likely be confused by what to pass in this function. Therefore choosing to express the possible actions explicitly with a DU is much better than leaving infinite options.

And now when the user click on the button, the form will be sent using the behavior selected.

## 4. Use it

So we have a model, we defined the renderer for that model and lastely we defined how to submit the data. Thanks to this we can now create form very quickly and easily by instiating the model and passing it to the render function.

Code 

Image

# Conclusion

Today we saw how we could create a form engine with a simple domain which allows quick creation of forms in WebSharper.UI.Next. Hope you liked this post. If you have any question leave it here or hit me on Twitter [@Kimserey_Lam](). See you next time!

# Other posts you will like!
