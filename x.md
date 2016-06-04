# SQLite functionalities

For the past few days, I have been writing a lot of `SQL` queries to query `SQLite` databases.
I had to extract data for reporting from `SQLite` databases where `SELECT-FROM-WHERE` queries weren't enough.
From that experience, I learnt few tricks that I am sure some of you will be interested in.
So today, I will list it all in this blog post.

This post is composed by six parts:

1. Use the built in date functions
2. Cast your string to integer with `CAST`
3. Transpose a table using `CASE` and `GROUP BY`
4. Query against a Json object with `json_extension`
5. Attach databases to `JOIN` on tables from different databases
6. Improve the performance of your query with `EXPLAIN QUERY PLAN`
