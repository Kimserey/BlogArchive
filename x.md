# Folders in Xamarin.Android and Xamarin.Forms

When using Xamarin.Forms and Xamarin.Android, chances are that you had at one point of time to access a local file.
Whether it was an image or a text file or even a local sqlite database, accessing a file from a Xamarin.Android project can be confusing.
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
