# Get started with SQLite in from Xamarin.Forms

Today I demonstrate how we can leverage sqlite to save data on mobile which can be useful for local application or to store cached data.

In this post, I will show how we can use Sqlite from Xamarin.Forms in an Android application. This post will be composed by 3 parts:

```
1. Get Sqlite.net
2. Dependency service and database path
3. Use Sqlite from Xamarin.Forms
 ```

## 1. Get Sqlite

The library that I always use is SQLite.net-pcl from `praeclarum` [https://www.nuget.org/packages/sqlite-net-pcl/](https://www.nuget.org/packages/sqlite-net-pcl/).
To not be confused with another SQLite.Net-PCL which is a fork of the original.
To get started, simply install Sqlite in the Android project and in the Xamarin.Forms project. Once installed, Sqlite namespace should be accessible. And we should also have access to `SqliteConnection`. In order to start a connection, we need to provide a database path. The database path is platform specific. It is usually stored in a private folder of the application and is not accessible by other application or can not be accessed via file browsing. 

```
// get the db location
var path = DependencyService.Get<IPathProvider>().GetDbPath(); 
var conn = new SQLiteConnection(path);
conn.CreateTable<Test>();
```

So the first thing to do is to define a platform specific service giving access to the folder.

## 2. Path service

In order to get the dB path, we need to inject a service implemented in the Android project which will return the dB path in the Xamarin.Forms project.

In Xamarin.Forms project:

```
public interface IPathProvider
{
    string GetDbPath();
}
```

In Droid project:

```
[assembly: Dependency(typeof(SqliteTest.Droid.PathProvider))]
namespace SqliteTest.Droid
{
	public class PathProvider: IPathProvider
	{
		public string GetDbPath()
		{
			var path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "test.db");
			return path;
		}
	}
}
```

_I talked about path in Android in a previous blog post [https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html](https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html)._

Now we can inject the service and retrieve the dbPath and we can instantiate a `SqliteConnection`.

## 3. Use Sqlite in Xamarin.Forms

We already have the package installed and we have a dependency service giving us access to sqlite.

All we need to do now is to create tables and create the sql queries.

SqliteNet works using Attributes, the one that I use the most are:
 - Table: to specify that the type is a table and have with a particular name, 
 - Column: same as table but for columns
 - Indexed: to index the column
 - NotNull
 - PrimaryKey
 - AutoIncrement
 - Collate Nocase: to specify a no case collation

With that we can now define our table:

```	
[Table("test_table")]
public class Test 
{
    [Column("id"), PrimaryKey, AutoIncrement, Collation("NOCASE")]
    public int Id { get; set; }
    [Column("text")]
    public string Text { get; set; }
}
```

We can create the table using the `CreateTable` generic function and insert an element with `Insert`. And finally we can query with `Find` or `Query` or `DeferreredQuery`.

```
using(var conn = = new SQLiteConnection(path))
{
    conn.CreateTable<Test>();
    var result = conn.Query<Test>("SELECT * FROM test_table");
}
```

We can access the db via `adb shell` but if we want to browse using a sqlite explorer, we can pull the db out using the command:

```
adb pull data/data/com.kimserey.sqlitetest/files/test.db
```

And that's all we need to get Sqlite working in Xamarin.Forms!

Source code available here - [https://github.com/Kimserey/SqliteTest)](https://github.com/Kimserey/SqliteTest)

# Conclusion

Today we learnt how to use Sqlite from Xamarin.Forms project. Sqlite being present in all mobiles, it is a very convenient way to store data or even temporary cache data locally on device. Hope you like this post! If you have any comments leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Other posts you will like

- Use Font awesome from your Xamarin.Android app - [https://kimsereyblog.blogspot.co.uk/2016/12/use-font-awesome-from-your-xamarinforms.html](https://kimsereyblog.blogspot.co.uk/2016/12/use-font-awesome-from-your-xamarinforms.html)
- Transform an activity asynchronous event to an awaitable task for Xamarin.Forms services - [http://kimsereyblog.blogspot.com/2016/12/transform-operation-from-xamarinandroid.html](http://kimsereyblog.blogspot.com/2016/12/transform-operation-from-xamarinandroid.html)
- Understand the difference between Internal and External folder storage in Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html](https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html)
- Use the Snackbar API with Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html](https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html)
- Build your own Line Chart for Xamarin.Forms (Part 2) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html)
- Build your own Line chart for Xamarin.Forms (Part 1) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html)

# Support me
[Support me by visting my website](https://www.kimsereylam.com). Thank you!

[Support me by downloading my app BASKEE](https://www.kimsereylam.com/baskee). Thank you!

![baskee](https://raw.githubusercontent.com/Kimserey/kimserey.github.io/master/img/readme/baskee_screenshots.png)

[Support me by downloading my app EXPENSE KING](https://www.kimsereylam.com/expenseking). Thank you!

![expense king](https://raw.githubusercontent.com/Kimserey/kimserey.github.io/master/img/readme/expenseking_screenshots.png)
