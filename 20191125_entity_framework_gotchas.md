# Entity Framework Core Optimizations

Last year I talked about [Entity Framework Core](https://kimsereyblog.blogspot.com/2017/05/saving-data-with-entity-framework-core.html). It is a easy and feature rich ORM which makes working with database in a .NET environment typesafe. But even though it makes things easy, there are ambiguous cases which can take us off guard. Today we will see three of this cases and how to deal with them.  

1. Client evaluation
2. Iteration
2. Include and ThenInclude
3. NoTracking

_For the following examples, I will be using SQLite with Entity Framework Core._

## tl;dr

1. Make sure that the query constructed in c# uses function that can be translated to SQL,
2. Make sure that there isn't an abnormal amount of queries created and that it does not iter item per item,
3. Make sure to use `Include` and `ThenInclude` for object relation to include them after query execution, before query execution it is not needed,
4. Use `NoTracking` for readonly queries to disable tracking on entity to yield better performance.

## 1. Client evaluation

The following example illustrates the first case, `client evaluation`:

```c#
var query = _dbContext.Posts
    .Where(p => p.BlogId == blogId && p.AuthorId == authorId && p.Title.Contains(title, StringComparison.OrdinalIgnoreCase));

return await query.ToListAsync();
```

We are executing a query and using `.Contains(string, StringComparison.OrdinalIgnoreCase)`, the compiler allows us to write it as it is valid code and Entity Framework runs properly. But if we look at the logs, we'll see a warning:

```c#
warn: Microsoft.EntityFrameworkCore.Query[20500]
      The LINQ expression 'where [p].Title.Contains(__title_2, OrdinalIgnoreCase)' could not be translated and will be evaluated locally.
```

This indicates that the `where` clause will be executed locally therefore all elements that satisfy `p.BlogId == blogId && p.AuthorId == authorId` will be fetched locally then filtered locally, in log we can see the query:

```c#
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (7ms) [Parameters=[@__blogId_0='?', @__authorId_1='?'], CommandType='Text', CommandTimeout='30']
      SELECT "p"."Id", "p"."AuthorId", "p"."BlogId", "p"."Content", "p"."Title"
      FROM "Posts" AS "p"
      WHERE ("p"."BlogId" = @__blogId_0) AND ("p"."AuthorId" = @__authorId_1)
```

This could be problematic if there were a lot of data as it would degrade the performance. Changing it to `.Contains(string)`:

```c#
var query = _dbContext.Posts
    .Where(p => p.BlogId == blogId && p.AuthorId == authorId && p.Title.Contains(title));

return await query.ToListAsync();
```

We can see from the query that it uses `instr(...)` which is supported by SQLite:

```c#
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (14ms) [Parameters=[@__blogId_0='?', @__authorId_1='?', @__title_2='?' (Size = 9)], CommandType='Text', CommandTimeout='30']
      SELECT "p"."Id", "p"."AuthorId", "p"."BlogId", "p"."Content", "p"."Title"
      FROM "Posts" AS "p"
      WHERE (("p"."BlogId" = @__blogId_0) AND ("p"."AuthorId" = @__authorId_1)) AND ((instr("p"."Title", @__title_2) > 0) OR (@__title_2 = ''))
```

## 2. Iterations

The second case is about `iterations`, consider the following:

```c#
var result = (await _dbContext.Blogs
    .Select(b => new
    {
        url = b.Url,
        posts = b.Posts.Select(p => new { title = p.Title, author = p.Author.Name })
    })
    .ToListAsync());
```

The execution of the query happens at `.ToListAsync()`, but in the query, we have an anonymous type which within the construct 

```c#
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (15ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      PRAGMA foreign_keys=ON;
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (4ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      SELECT "b"."Url", "b"."Id"
      FROM "Blogs" AS "b"

info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (0ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      PRAGMA foreign_keys=ON;
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (6ms) [Parameters=[@_outer_Id='?'], CommandType='Text', CommandTimeout='30']
      SELECT "p"."Title", "p.Author"."Name" AS "author"
      FROM "Posts" AS "p"
      INNER JOIN "Authors" AS "p.Author" ON "p"."AuthorId" = "p.Author"."Id"
      WHERE @_outer_Id = "p"."BlogId"

info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (0ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      PRAGMA foreign_keys=ON;
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (1ms) [Parameters=[@_outer_Id='?'], CommandType='Text', CommandTimeout='30']
      SELECT "p"."Title", "p.Author"."Name" AS "author"
      FROM "Posts" AS "p"
      INNER JOIN "Authors" AS "p.Author" ON "p"."AuthorId" = "p.Author"."Id"
      WHERE @_outer_Id = "p"."BlogId"

info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (0ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      PRAGMA foreign_keys=ON;
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (1ms) [Parameters=[@_outer_Id='?'], CommandType='Text', CommandTimeout='30']
      SELECT "p"."Title", "p.Author"."Name" AS "author"
      FROM "Posts" AS "p"
      INNER JOIN "Authors" AS "p.Author" ON "p"."AuthorId" = "p.Author"."Id"
      WHERE @_outer_Id = "p"."BlogId"
```

```c#
var result = (await _dbContext.Blogs
    .Include(b => b.Posts)
    .ThenInclude(p => p.Author)
    .ToListAsync())
    .Select(b => new
    {
        url = b.Url,
        posts = b.Posts.Select(p => new { title = p.Title, author = p.Author.Name })
    });
```

```c#
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (0ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      PRAGMA foreign_keys=ON;
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (0ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      SELECT "b"."Id", "b"."Url"
      FROM "Blogs" AS "b"
      ORDER BY "b"."Id"

info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (0ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      SELECT "b.Posts"."Id", "b.Posts"."AuthorId", "b.Posts"."BlogId", "b.Posts"."Content", "b.Posts"."Title", "p.Author"."Id", "p.Author"."Name"
      FROM "Posts" AS "b.Posts"
      INNER JOIN "Authors" AS "p.Author" ON "b.Posts"."AuthorId" = "p.Author"."Id"
      INNER JOIN (
          SELECT "b0"."Id"
          FROM "Blogs" AS "b0"
      ) AS "t" ON "b.Posts"."BlogId" = "t"."Id"
      ORDER BY "t"."Id"
```

## 2. Include and ThenInclude

```c#
var result = (await _dbContext.Blogs
    .Select(b => new
    {
        url = b.Url,
        posts = b.Posts.Select(p => new { title = p.Title, author = p.Author.Name }) // <-- Author is accessible
    })
    .ToListAsync());
```

```c#
var result = (await _dbContext.Blogs.ToListAsync())
    .Select(b => new
    {
        url = b.Url,
        posts = b.Posts.Select(p => new { title = p.Title, author = p.Author.Name }) // <-- System.ArgumentNullException: 'Value cannot be null.' -- 'Posts' is null.
    });
```

```c#
var result = (await _dbContext.Blogs
    .Include(b => b.Posts)    
    .ThenInclude(p => p.Author) // <-- Include Posts in Blog then include Author in Post in the query
    .ToListAsync())
    .Select(b => new
    {
        url = b.Url,
        posts = b.Posts.Select(p => new { title = p.Title, author = p.Author.Name }) // <-- Posts and Author are included in the query
    });
```

## 3. NoTracking

```
.AsNoTracking()
```