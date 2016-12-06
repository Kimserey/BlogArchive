# Transform an operation from a Xamarin.Android activity to an awaitable task to be used from a Xamarin.Forms service

Today I want to share a neat trick which I have been using a lot - __transform an asynchronous operation (triggered with StartActivityFromResult) from an Android Activity to an awaitable task__ - which then can be used with async await keywords in a Xamarin.Forms PCL project.

1. Scenario
2. CustomPickActivity
3. TaskCompletionSource in service

##1. Scenario

I needed to pick a file from my documents and execute an action using the selected file.

##2. CustomPickerActivity

To pick a file from our Xamarin.Forms project, we use a service which starts a picker activity.

```
public class FilePicked : EventArgs
{
    public string AbsolutePath { get; set; }
}

[Activity]
public class PickActivity: Activity
{
    static event EventHandler<FilePicked> OnFilePicked;

    protected override void OnCreate(Bundle savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        var intent = new Intent();
        intent.SetType("image/*");
        intent.SetAction(Intent.ActionPick);
        StartActivityForResult(intent, 0);
    }

    protected override void OnActivityResult(int requestCode, Result resultCode, Intent data)
    {
        base.OnActivityResult(requestCode, resultCode, data);

        if (requestCode == 0 && resultCode == Result.Ok)
        {
            if (OnFilePicked != null)
            {
                OnFilePicked(this, new FilePicked { AbsolutePath = data.Data.Path });
            }
        }
        
        Finish(); 
    }
}
```

When the activity is created, another activity is started with a `ActionPick` intent. Once picked, the result is given back in the `OnActivityResult`.
I also added an event `static event EventHandler<FilePicked> OnFilePicked`  and triggered it from within the ActivityResult `OnFilePicked(this, new FilePicked { AbsolutePath = data.Data.Path })`.
This is important for the next step.

##3. TaskCompletionSource in service

The next step is to build the service which will be called from the Xamarin.Forms PCL.
The trick here is to use a TaskCompletionSource to create a task which starts immediately and gets completed only when the event in the activity is triggered.

Also, we use interlock methods to ensure that at any point only one task is created. If not we directly return with an error.

_This is important because the event is static, concurrent call to the service will yield unexpected behaviours._

```
public class PickFileService: IPickFileService
{
    TaskCompletionSource<string> tcs;

    public Task<string> PickFile()
    {
        var uniqueId = Guid.NewGuid();
        var next = new TaskCompletionSource<string>(uniqueId); 

        // Interlocked.CompareExchange(ref object location1, object value, object comparand)
        // Compare location1 with comparand.
        // If equal replace location1 by value.
        // Returns the original value of location1.
        // ---
        // In this context, tcs is compared to null, if equal tcs is replaced by next,
        // and original tcs is returned.
        // We then compare original tcs with null, if not null it means that a task was 
        // already started.
        if (Interlocked.CompareExchange(ref tcs, next, null) != null)
        {
            return Task.FromResult<string>(null);
        }

        EventHandler<FilePicked> handler = null;

        handler = (sender, e) => {
            
            // Interlocaked.Exchange(ref object location1, object value)
            // Sets an object to a specified value and returns a reference to the original object.
            // ---
            // In this context, sets tcs to null and returns it.
            var task = Interlocked.Exchange(ref tcs, null);

            PickActivity.OnFilePicked -= handler;

            if (!String.IsNullOrWhiteSpace(e.AbsolutePath))
            {
                task.SetResult(e.AbsolutePath);
            }
            else
            {
                task.SetCanceled();
            }
        };

        PickActivity.OnFilePicked += handler;
        var pickIntent = new Intent(Forms.Context, typeof(PickActivity));
        pickIntent.SetFlags(ActivityFlags.NewTask);
        Forms.Context.StartActivity(pickIntent);

        return tcs.Task;
    }
}
```

By doing this, we now have a way to return a task which only completes when a file is picked or the activity cancelled.

This then allow us to `await` the pick intent when calling the service from our Xamarin.Forms project.

```
var buttonPickFile = new Button { Text = "Pick file" };

buttonPickFile.Clicked += async (sender, e) =>
{
    var file = await DependencyService.Get<IPickFileService>().PickFile();
    await page.DisplayAlert("File picked", file, "OK");
};
```

Thanks to this trick, we can now await and execute something after the file is picked like here, we display an alert. But I am sure you will find something more important to do than display an alert!

[Full source code available here](https://github.com/Kimserey/BoundServiceTest/blob/master/Droid/PickActivity.cs)

# Conclusion

Today we saw how we can transform a pick activity to an awaitable task which can be used from a service in Xamarin.Forms projects. Using TaskCompletionSource together with event to transform event/callback codes to Task is a very nice trick to know. If you have any question, leave it here or hit on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Support me
[Support me by downloading my app BASKEE](https://www.kimsereylam.com/baskee). Thank you!

![baskee](https://raw.githubusercontent.com/Kimserey/kimserey.github.io/master/img/readme/baskee_screenshots.png)

# Other posts you will like

- Why I built Baskee? - [https://kimsereyblog.blogspot.co.uk/2016/11/why-i-created-baskee.html](https://kimsereyblog.blogspot.co.uk/2016/11/why-i-created-baskee.html)
- Understand the difference between Internal and External folder storage in Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html](https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html)
- Use the Snackbar API with Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html](https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html)
- Build your own Line Chart for Xamarin.Forms (Part 2) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html)
- Build your own Line chart for Xamarin.Forms (Part 1) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html)
- Make a splash screen in Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html](https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html)
