# Saving data with Entity Framework Core with SQLite

Entity Framework is a framework abstracting away all the complexity of dealing with storage. This abstraction is also known as ORM ~ object-relational mapping.
There is a number of provider which are implementation of the storage like SQL server or MySql or also SQLite, the one we will be seeing in this post.
SQLite is a embedded database. The whole database is contained within a single `.db` file which makes it highly portable, so portable that it is the default database installed in mobile OS like `iOS` and `Android`. It is extremely easy to use and to maintain. It also offer a powerful implementation of `SQL`. Today we will see how we can make use of `Entity Framework` with `SQLite provider` in a `ASP.NET Core` application.

```
 1. Install EF and create a new DbContext
 2. Create migrations
 3. Use in ASP NET Core
``` 

## 1. Install EF and create a new DbContext

Start by installing the packages:

```
Install-Package Microsoft.EntityFrameworkCore.SQLite
```

Once we have installed `EF Core SQLite`, we will create our first `DbContext`:

```
public class PersonDbContext : DbContext
{ 
    public DbSet<Person> Persons { get; set; }
}
```

With our first `Person` model:

```
public class Person
{
    public int Id { get; set; }
    [Required]
    public string Name { get; set; }
}
```

Also installing `EF Core SQLite` gives us access to the `.UseSqlite` extension on the DbContext builder which we can register in the services configuration:

```
public void ConfigureServices(IServiceCollection services)
{
    services.AddDbContext<PersonDbContext>(builder =>
        builder.UseSqlite("Data source=persons.db")
    );

    ... other configurations
}
```

Now that we have configured our first DbContext, what we need to do is to create the database.
While we could do that manually, `EF` provides a set of tools which can be used to create migrations.
Migrations are a big advantage of `EF`, in the event of us having to change the database after data have already been added, we will be in measure to use the migration to automate the process.

This way of developing ~ creating the object model, generating migrations out of the object model, creating database by running migrations ~ is also known as `Code first design`.

In order to generate the migration code

https://visualstudiogallery.msdn.microsoft.com/0e313dfd-be80-4afb-b5e9-6e74d369f7a1/view/Reviews/

EF core uses .NET Core CLI for migration:

[https://docs.microsoft.com/en-us/ef/core/miscellaneous/cli/dotnet](https://docs.microsoft.com/en-us/ef/core/miscellaneous/cli/dotnet)

1. Install EF tools

Start by adding the `DotNetCliToolReference` in the `.csproj`:

```
<ItemGroup>
    <DotNetCliToolReference Include="Microsoft.EntityFrameworkCore.Tools.DotNet" Version="1.0.0" />
</ItemGroup>
```

Then add the package reference `Microsoft.EntityFrameworkCore.Design` which is needed for the EF design tools.

`DotNetCliToolReference` is used to extend the functionality of the `dotnet cli`.

You can add the package either with nuget or by running `dotnet add package Microsoft.EntityFrameworkCore.Design`.


2. Add migration

```
dotnet ef add migrations [Name]
```

Then run

```
dotnet ef database update
```

3. 