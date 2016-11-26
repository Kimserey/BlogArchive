# Folders in Xamarin.Android and Xamarin.Forms

When using Xamarin.Forms and Xamarin.Android, chances are that you had at one point of time to access a local file.
Whether it is an image or a text file or even a local sqlite database, accessing a file from a Xamarin.Android project can be confusing.
Today I will show you how you can get the absolute path of the different folders available in Xamarin.Android and we will see how we can access the folder from Xamarin.Forms.

This post is composed 3 parts:

```
1. Internal folder
2. Public and private external folders
3. Access folders from Xamarin.Forms.
```

## 1. Internal folder

The internal folder is a folder specific to your application.
It can only be access within your application and no other applications can touch the files within that folder.

You can get it using the following:

```
Android.App.Application.Context.FilesDir.AbsolutePath
```

Use this storage to store document specific to your application which will not be accessible from else where.
Another important point is that when the user uninstall the application, all the data within that folder will be removed.

## 2. Public and private external folders

The external folder is a folder accessible by anyone.
It can be mounted on a computer and any files is publicly available. Also any app with EXTERNAL_STORAGE read access will be able to access these files.

There are two type of external folders, `public` and `private`.
The difference beeing that `private` files will get deleted when your app is uninstall.

_Private files on external folders are still accessible by anyone._

The public external folder can be accessed using:
```
Android.OS.Environment.ExternalStorageDirectory.AbsolutePath
```

And the private external folder can be accessed using:
```
Application.Context.GetExternalFilesDir(null).AbsolutePath
```

## 3. Access folder paths from Xamarin.Forms

To access folder paths from Xamarin.Forms we will need to create a service and get it through the dependency service.

To do that we can create an interface IPathService in the Xamarin Forms project.

```
public interface IPathService 
{
    string InternalFolder { get; }
    string PublicExternalFolder { get; }
    string PrivateExternalFolder { get; }
}
```

And in the Android project we can add the implementation and add the dependency on the assembly level.

```
[assembly: Dependency(typeof(MyApp.PathService))]
namespace MyApp
{
    public class PathService: IPathService
    {
        public string InternalFolder
        {
            get 
            { 
                return Android.App.Application.Context.FilesDir.AbsolutePath;
            }
        }

        public string PublicExternalFolder
        { 
            get
            {
                return Android.OS.Environment.ExternalStorageDirectory.AbsolutePath;
            }
        }

        public string PrivateExternalFolder
        {
            get 
            {
                return Application.Context.GetExternalFilesDir(null).AbsolutePath; 
            }
        }
    }
}
```

We can then access the path from anywhere in our app using:

```
DependencySerivce.Get<IPathService>().InternalFolder
```

# Conclusion

Today we learnt the different type of folder available in Android. Internal vs external and public external vs private external.
Use internal folder if you want everything to be only contained in your app and prevent other apps from messing with your content. Use external to save file which are not application lifecycle threatening, photos taken from your app our good example. Bear in mind that any content stored in external folders can be removed by the user, even the external storage might not be always available.
I hope this clear up the differences! 
Thanks for reading my post, if you have any questions leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). 
Oh and don't forget to support me by checking out my app [Baskee](https://www.kimsereylam.com/baskee). See you next time!

# Other post you will like!

- Why I built Baskee? - [https://kimsereyblog.blogspot.co.uk/2016/11/why-i-created-baskee.html](https://kimsereyblog.blogspot.co.uk/2016/11/why-i-created-baskee.html)
- Use the Snackbar API with Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html](https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html)
- Build your own Line Chart for Xamarin.Forms (Part 2) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html)
- Build your own Line chart for Xamarin.Forms (Part 1) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html)
- Make a splash screen in Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html](https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html)
- Make an accordion view in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html)
