# What I learnt with SQLite

For the past few days, I have been writing a lot of `SQL` queries to query `SQLite` databases.
I had to extract data for reporting purposes from `SQLite` databases where simple `SELECT-FROM-WHERE` queries weren't enough.
From this experience, I learnt few tricks that I am sure some of you will be interested in.
So today, I will list it all in this blog post.

This post is composed by six parts:

1. Use the built in date functions
2. Cast your string to integer with `CAST`
3. Transpose a table using `GROUP BY`, `CASE` and `Aggregate functions`
4. Concatenate value with `||`
5. Attach databases to `JOIN` on tables from different databases
6. Improve the performance of your query with `EXPLAIN QUERY PLAN`

_The parts aren't related with one another._

## 1. Use the built in date functions

`strftime` is the main function for datetime manipulation. It takes a `format`, a `string` date and some `modifiers`.
Here are the format extracted from [https://www.sqlite.org/lang_datefunc.html](https://www.sqlite.org/lang_datefunc.html).
```
%d		day of month: 00
%f		fractional seconds: SS.SSS
%H		hour: 00-24
%j		day of year: 001-366
%J		Julian day number
%m		month: 01-12
%M		minute: 00-59
%s		seconds since 1970-01-01
%S		seconds: 00-59
%w		day of week 0-6 with Sunday==0
%W		week of year: 00-53
%Y		year: 0000-9999
```

Using `strftime`, you can get the day of the month, the month number, the year and other information out of a date. 

```
SELECT strftime('%d', '2016-01-04');
> 04

SELECT strftime('%Y', '2016-01-04');
> 2016
```

This is useful when you need to `GROUP BY` per week, per month or per year.

There are some shortcut functions that can be used like `date(...)` which is equivalent to calling `strftime('%Y-%m-%d', ...)`.

```
date(...)	   ->	strftime('%Y-%m-%d', ...)
time(...)	   ->	strftime('%H:%M:%S', ...)
datetime(...)   ->	strftime('%Y-%m-%d %H:%M:%S', ...)
```

The `modifiers` are used to modify the date passed as argument.
```
NNN days
NNN hours
NNN minutes
NNN.NNNN seconds
NNN months
NNN years
start of month
start of year
start of day
weekday N
unixepoch
localtime
utc
```

Very useful when you need to add or substract from the date, for example you can use `+2 months` to have the date in two month time from the date passed as argument.
```
SELECT date('2016-02-04', '+2 months');
> 2016-04-04
```

If you are saving your `datetime` as ticks from `DateTime.Now.Ticks`, you can use `unixepoch` with the following calculation.

```
SELECT date(timestamp / 10000000 - 62135596800, 'unixepoch')

--------------
62135596800 is the number of second from 01/01/0001 till 01/01/1970
/10000000 is the conversion from ticks to seconds
```

##2. Cast your string to integer with `CAST`

When you handle `string` values it is sometime required to `cast` those to `integer` (or to another type).
For example when you get a month from a `date(...)`, it returns as a `string`.
In order to perform a comparaison, it is necessary to `cast` it.

```
SELECT strftime('%m','2016-04-01');
> 04

SELECT CAST (strftime('%m','2016-04-01') AS Integer);
> 4
```

##3. Transpose a table using `GROUP BY`, `CASE` and `Aggregate functions`

In one the database I worked on, the values were stored in three columns `id`, `key` and `value`.
This table gathers all the data sent from a form from our app.
`id` is the identifier of the form, `key` is the key of the field and `value` is the value of the field.

_The table is designed this way to handle the dynamic nature of the forms. 
Fields can be added or removed every day, depending on client requirements, so it would not be possible to use the value of `keys` as table columns._

Storing the values this way makes it difficult to query directly.
What we need to do is to `transpose` the tabe.

For example if you have a table like that:

```
id  key     value
--  ---     -----
1   amount  10.0
1   date    2016-03-01
1   name    Kim
2   amount  32.0
2   date    2016-03-02
2   name    Sam
3   amount  12.5
3   date    2016-03-03
3   name    Tom
```

To work with this table we need to transpose it by taking the `key`s and transform it to columns.
```
id | key | value --> id | date | name | amount
```

In order to do that we need to `GROUP BY` the id.
We can visualize the `GROUP BY` like so:
```
SELECT (some aggregate function) FROM forms GROUP BY id


1
    1   amount  10.0
    1   date    2016-03-01
    1   name    Kim

2
    2   amount  32.0
    2   date    2016-03-02
    2   name    Sam

3
    3   amount  12.5
    3   date    2016-03-03
    3   name    Tom
```

In the `SELECT` we then have access to each group where we can use `Aggregate function` to extract a single value.
[https://www.sqlite.org/lang_aggfunc.html](https://www.sqlite.org/lang_aggfunc.html)
```
avg(X)              - calculate the average
count(X)            - count the number of non null values
count(*)            - count the number of rows
group_concat(X)     - concat the string values
group_concat(X,Y)   - concat the string values using Y as seperator
max(X)              - keep the max of all values
min(X)              - keep the min of all values
sum(X)              - sum all values (SQL implementation)
total(X)            - sum all values (SQLite implementation)
```

We can use `max(...)` combined with `CASE` to select the correct value in the grouping for each column.
`CASE` is the `if else` of `SQL`.
For example to select to extract the name as a column, we would do the following:
```
SELECT max(CASE WHEN key = 'name' THEN value END) as name FROM forms GROUP BY id;

name
----
Kim
Sam
Tom
```

`CASE WHEN key = 'name' THEN value END` would take the `value` if the `key = 'name'` else it would return `NULL`.
`max(...)` returns the `max` value which is the value where the `key = name` since all other values are set to `NULL`.
We then apply the same pattern for the other columns:
```
SELECT 
    id,
    max(CASE WHEN key = 'name' THEN value END) AS name,
    max(CASE WHEN key = 'date' THEN value END) AS date,
    sum(CASE WHEN key = 'amount' THEN value END) AS amount
FROM forms
GROUP BY id

id  name    date        amount
--  ----    ----        -----
1   Kim     2016-03-01  10.0
2   Sam     2016-03-02  32.0
3   Tom     2016-03-03  12.5
```

Nice, we transposed our table to a table that we can use now.
After that it is easy to use this `SELECT` as a subselect to perform some other filtering.
```
SELECT
    id,
    name,
    date,
    amount
FROM (SELECT 
            id,
            max(CASE WHEN key = 'name' THEN value END) AS name,
            max(CASE WHEN key = 'date' THEN value END) AS date,
            sum(CASE WHEN key = 'amount' THEN value END) AS amount
      FROM forms
      GROUP BY id)
WHERE amount > 20

id  name    date        amount
--  ----    ----        -----
2   Sam     2016-03-02  32.0
```

## 4. Concatenate values with `||`

If your table has columns that you need to concatenate into a single value, you can use `||`.
```
SELECT (hello || ' ' || world) AS mesasge 
FROM (SELECT 'Hello' as hello, 'World' as world);

> Hello World
```

## 5. Attach databases to `JOIN` on tables from different databases

If your query requires a `JOIN` between __tables in different databases__,
you can use `attach 'second-database.db' as second;`.
This will allow you to have access to the tables in `second-database.db`.

```
attach 'second-database.db' as second;

SELECT * FROM forms JOIN second.othertable as other ON other.id = forms.id
```

## 6. Improve the performance of your query with `EXPLAIN QUERY PLAN`

[https://www.sqlite.org/eqp.html](https://www.sqlite.org/eqp.html)

If your queries are slow, it is probably because your table isn't indexed correctly.
In order to pinpoint the issue, you can use `EXPLAIN QUERY PLAN (your query)`.
The result of this command will give you guidance on what to index in your table.

Using the same table as 3. we can run `EXPLAIN QUERY PLAN` on some queries and see the result.
```
EXPLAIN QUERY PLAN SELECT * FROM forms WHERE id = 2;
0|0|0|SCAN TABLE forms
```

`SCAN TABLE` is the worst result you can get.
Since we querying on `id`, let's create an index on id.

```
CREATE INDEX IF NOT EXISTS idx_forms_id ON forms (id);

EXPLAIN QUERY PLAN SELECT * FROM forms WHERE id = 2;
0|0|0|SEARCH TABLE forms USING INDEX idx_forms_id (id=?)
```

# Conclusion

SQLite has a lot of cool features and there are many more features that I haven't discovered yet.
Thanks to [@nbevans](https://twitter.com/nbevans) for showing me how to use some of these features.
Learning how to use these features really helped me to write better queries and ultimately helped in improving the performance of our system.
Hope you learnt something new today with this post and if you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).
See you next time!
