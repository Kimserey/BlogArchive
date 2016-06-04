# SQLite functionalities

For the past few days, I have been doing a lot of SQLite.
I have to admit, I used to tell myself that I would never need SQL since a lot of ORMs are available.
But at the end of the day it would be ridiculous to use an ORM to do some simple queries.
After working few days writing queries against SQLite dbs, I got to say that I am very impressed. A lot of functionalities are available out of the box and writing SQL queries for SQLite isn't as bad as the world makes it look like.

So today, in order to keep a trace for future references, I will explain all the good things I've learnt so far with SQLite:

1. Use the built in date functions
2. Cast your string to integer with `CAST`
3. Transpose a table using `CASE` and `GROUP BY`
4. Query against a Json object with `json_extension`
5. Attach databases to `JOIN` on tables from different databases
6. Improve the performance of your query with `EXPLAIN QUERY PLAN`
