# Saving data with Entity Framework Core with SQLite

Entity Framework is a framework abstracting away all the complexity of dealing with storage. This abstraction is also known as ORM ~ object-relational mapping.
There is a number of provider which are implementation of the storage like SQL server or MySql or also SQLite, the one we will be seeing in this post.
SQLite is a embedded database. The whole database is contained within a single `.db` file which makes it highly portable, so portable that it is the default database installed in mobile OS like `iOS` and `Android`. It is extremely easy to use and to maintain. It also offer a powerful implementation of `SQL`. Today we will see how we can make use of `Entity Framework` with `SQLite provider` in a `ASP.NET Core` application.

```
 1. Install EF tools
 2. Add a new DbContext
 3. Create migrations
 4. Use in ASP NET Core
``` 



Install-Package Microsoft.EntityFrameworkCore

Install-Package Microsoft.EntityFrameworkCore.SQLite

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