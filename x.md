# Transform an operation from a Xamarin.Android activity to an awaitable task to be used from a Xamarin.Forms service

Today I want to share a neat trick which I have been using a lot - __transform an asynchronous operation from an Android Activity to an awaitable task__ - which then can be used with async await keywords in a Xamarin.Forms pcl project.

1. Scenario
2. CustomPickActivity
3. TaskCompletionSource in service

##1. Scenario

I need to pick a file from my documents and execute an action using the selected file.

##2. CustomPickerActivity

To pick a file from our Xamarin.Forms project, we have a service which starts a picker activity.
Because we want to perform extra operations once the file is picked, we need to created our own custom picker activity to start using StartActivityForResult method.

(code)

When the external activity returns, the result is given back in the ActivityResult.

(code)

In order to inform our service that a file has been picked, we create a static event and trigger it from within the ActivityResult.

That will be our CustomPickActivity with one purpose - spawn a pick activity and handle the result. Next we will look at how to start this activity from our service.

##3. TaskCompletionSource in service

The trick here is to use a TaskCompletionSource to create a task which starts immediately and gets completed only when the event in the activity is triggered.

Also, we use interlock methods to ensure that at any point only one task is created. If not we directly return with an error.

_This is important because the event is static, concurrent call to the service will yield unexpected behaviours._

(code)

By doing this, we now have a way to return a task which only completes when a file is picked or the activity cancelled.

This then allow us to write the following when calling the service from our Xamarin.Forms project.

(code)

And that's it!

Full source code available here - []()

# Conclusion

Today we saw how we can transform a pick activity to an awaitable task which can be used from a service in Xamarin.Forms projects. Using TaskCompletionSource together with event to transform event/callback codes to Task is a very nice trick to know. If you have any question, leave it here or hit on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Support me
Support me by downloading my app [BASKEE](https://www.kimsereylam.com/baskee). Thank you!

![baskee](https://raw.githubusercontent.com/Kimserey/kimserey.github.io/master/img/readme/baskee_screenshots.png)

# Other posts you will like

- Why I built Baskee? - [https://kimsereyblog.blogspot.co.uk/2016/11/why-i-created-baskee.html](https://kimsereyblog.blogspot.co.uk/2016/11/why-i-created-baskee.html)
- Understand the difference between Internal and External folder storage in Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html](https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html)
- Use the Snackbar API with Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html](https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html)
- Build your own Line Chart for Xamarin.Forms (Part 2) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html)
- Build your own Line chart for Xamarin.Forms (Part 1) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html)
- Make a splash screen in Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html](https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html)
