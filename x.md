Use Android snackbar for your Xamarin Android project from Xamarin Forms

In order to provide notifications Android has introduced the Snackbar api. You might have noticed some usage of it for example when we close a tab in chrome we get the notification that the tab was closed.

This is the snackbar. Today we will see how to use the snack bar api with Xamarin Android and how we can call it from our Xamarin Forms project.

This post is composed by 3 parts:

1. When is the snackbar useful
2. Implement the snackbar api
2. Call it from Xamarin.Forms

1.

The snackbar can be use to notify the user that something had happen.
Something good about it is that it handles the layout for you. The snackbar will find by itself on which view to appear and will push the layout up, neat feature.
Another very important aspect is that it provides a way to execute an action.

The most obvious action is the undo action which allows the user to rectify an action done by mistake - with touchscreens it is highly possible that users make mistakes like clicking on the wrong icon. The snackbar then provides an instant non obstrusive way to rectify the error.

Instant because as soon as the user click, the undo is presented. Non obstrusive because if that action wasn't a mistake, the user can just continue her experience flow and the snackbar dismiss itself after a set amount of seconds.

I hope now you are convinced that the snackbar is amazing so let's start by looking how we can implement it in Xamarin.Android

2.
To implement the snackbar api you need the Android.Widget library.

Then the functions to used are available via the Snackbar class.

Make and Show are the main function.
Make can be used to instantiate a new snackbar and when you need to show it, call show.

An action with a title can also be given to the snackbar to create a button like the UNDO.

Now to use the snackbar from XamarinForms, we need to call it from a service which will be injected into the XamarinForms project.

3.

We define an interface
