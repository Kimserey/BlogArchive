# Get started with SQLite in from Xamarin.Forms

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

We already have the package installed and we have a dependency service giving us access to sqlite.

All we need to do now is to create tables and create the sql queries.

SqliteNet works using Attributes, the main one are
. Table to specify that the type is a table and have with a particular name, 
. Column same as table but for columns
. Indexed
. NotNull
. PrimaryKey
. AutoIncrement
. Colate Nocase?

With that we can now define our table:
'''
'''
We can create the table using the CreateTable generic function and insert an element with Insert

And finally we can query with Find or Query or DeferreredQuery.

And that's all we need to get Sqlite working in Xamarin.Forms!

# Conclusion

Today we learnt how to use Sqlite from Xamarin.Forms project. Sqlite being present in all mobiles, it is a very convenient way to store data or even temporary cache data locally on device. Hope you like this post! If you have any comments leave it here or hit me on Twitter @Kimserey_Lam. See you next time!
