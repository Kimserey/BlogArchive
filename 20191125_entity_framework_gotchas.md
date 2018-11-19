# Entity Framework Core Gotchas

1. Forcing iterations
2. Include and ThenInclude
3. NoTracking

## 1. Client evaluation

```c#
var query = _dbContext.Posts
    .Where(p => p.BlogId == blogId && p.AuthorId == authorId && p.Title.Contains(title, StringComparison.OrdinalIgnoreCase));

return await query.ToListAsync();
```

```c#
warn: Microsoft.EntityFrameworkCore.Query[20500]
      The LINQ expression 'where [p].Title.Contains(__title_2, OrdinalIgnoreCase)' could not be translated and will be evaluated locally.
```

```c#
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (7ms) [Parameters=[@__blogId_0='?', @__authorId_1='?'], CommandType='Text', CommandTimeout='30']
      SELECT "p"."Id", "p"."AuthorId", "p"."BlogId", "p"."Content", "p"."Title"
      FROM "Posts" AS "p"
      WHERE ("p"."BlogId" = @__blogId_0) AND ("p"."AuthorId" = @__authorId_1)
```

```c#
var query = _dbContext.Posts
    .Where(p => p.BlogId == blogId && p.AuthorId == authorId && p.Title.Contains(title));

return await query.ToListAsync();
```

```c#
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (14ms) [Parameters=[@__blogId_0='?', @__authorId_1='?', @__title_2='?' (Size = 9)], CommandType='Text', CommandTimeout='30']
      SELECT "p"."Id", "p"."AuthorId", "p"."BlogId", "p"."Content", "p"."Title"
      FROM "Posts" AS "p"
      WHERE (("p"."BlogId" = @__blogId_0) AND ("p"."AuthorId" = @__authorId_1)) AND ((instr("p"."Title", @__title_2) > 0) OR (@__title_2 = ''))
```

```c#
var result = (await _dbContext.Blogs
    .Select(b => new
    {
        url = b.Url,
        posts = b.Posts.Select(p => new { title = p.Title, author = p.Author.Name })
    })
    .ToListAsync());
```

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