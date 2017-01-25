# Workaround for ListModel input losing focus in WebSharper F#

Few months ago I explained how ListModel worked [](). Today I would like to share a recurring issue that I have. The issue is that my input keep losing focus every time the ListModel values changed. There's a easy solution to that which I demonstrate by first show the initial code and explaining what is going on and why the focus is lost then I will explain how we can work around it.

This post will be composed by two parts:

```
 1. Why the inputs lose focus
 2. How to prevent it
```

## 1. Why the inputs lose focus

The code is the following

If you try this you will see that the list gets updated but the input focus is lost after each changes.

The problem comes from the fact that the form itself is observing the list changes. If we look at how the form is rendered, it is rendered in the View callback therefore every time we change the ListModel the whole form Dom is re-rendered and since the old one is removed, we lose focus on the input.

So what can we do about it?

## 2. How to prevent it

If the number of elements don't change, we actually don't need to observe the list. We can take its initial value and render the form. Like that the Dom will not be deleted each time.

If we need to observe the list changes, observe when elements are added or removed, the form will have to be re-rendered and we will have to lose focus.

To work around that, we can use a Snapshot combined with a Update button.

Snapshot are used with a combined Var, I call it a trigger. It is just a Var<unit> which, when set, will trigger the refresh of the view.

So here's how we use it:

And we add an Update button to get the user to click to update the list.

So even though it is not refreshing "live", users still understand how to get the list to update.

# Conclusion

Today we saw how we could work around the problem of losing focus in input when ListModle gets updated. Hope you liked this post, if you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](). See you next time!
