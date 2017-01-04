Today I demonstrate how we can leverage sqlite to save data on mobile which can be useful for local application or to store cached data.

In this post, I will show how we can use Sqlite from Xamarin.Forms in an Android application. This post will be composed by 3 parts:

1. Get Sqlite.net
2. Dependency service and database path
3. Use Sqlite from Xamarin.Forms

## 1. Get Sqlite

The library that I always use is SQLite.net-pcl from ...
To not be confused with SQLite.Net-PCL which is a fork of the original.

To get started, simply install Sqlite in the Android project and in the Xamarin.Forms project.

Once installed, Sqlite namespace should be accessible. And we should also have access to SqliteConnection.

In order to start a connection, we need to provide a database path.

The database path is platform specific. It is usually stored in a private folder of the application and is not accessible by other application or can not be accessed via file browsing.

So we need to define a platform specific service giving access to the folder.

## 2. Path service

In order to get the dB path, we need to inject a service implemented in the Android project which will return the dB path in the Xamarin.Forms project.

...
...

I talked about path in Android in a previous blog post. [link].

Now we can inject the service and retrieve the dbPath and we can instantiate a SqliteConnection.

## 3. Use Sqlite in Xamarin.Forms

We have
