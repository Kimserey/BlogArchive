# SQLite functionalities

For the past few days, I have been writing a lot of `SQL` queries to query `SQLite` databases.
I had to extract data for reporting from `SQLite` databases where `SELECT-FROM-WHERE` queries weren't enough.
From that experience, I learnt few tricks that I am sure some of you will be interested in.
So today, I will list it all in this blog post.

This post is composed by six parts:

1. Use the built in date functions
2. Cast your string to integer with `CAST`
3. Transpose a table using `GROUP BY`, `CASE` and `Aggregate functions`
4. Concatenate value with `||`
5. Attach databases to `JOIN` on tables from different databases
6. Improve the performance of your query with `EXPLAIN QUERY PLAN`


## 1. Use the built in date functions

`strftime` is the main function, it takes a `format`, a `string` date and some `modifiers`.
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

The `modifiers` are used to modify the date given.
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

When you handle your value as `string` it is sometime required to `cast` to `integer`.
For example when you get a month from a `date(...)`, it returns as a `string`.
In order to perform a comparaison, it is necessary to `cast` it.

```
SELECT strftime('%m','2016-04-01');
> 04

SELECT CAST (strftime('%m','2016-04-01') AS Integer);
> 4
```

##3. Transpose a table using `GROUP BY`, `CASE` and `Aggregate functions`

In one the database I had to work, the value were stored in three columns `id`, `key` and `value`.
This table gathers all the data sent from a form from our app.
`id` is the identifier of the form, `key` is the key of the field and `value` is the value of the field.

_If you are thinking why is the table designed this way, it is meant to handle the dynamic nature of the forms. 
Fields can be added or removed every day, depending on client requirements, so it would not be possible to use the field `keys` as table columns._

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

In the `SELECT` we then have access to each group.
We need to use `Aggregate function` to extract a single value.
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
`max(...)` would then return the last non null value, in this example only the `name` would be a non null value.
We then do the same for each column:
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

## 4. Concatenate value with `||`
## 5. Attach databases to `JOIN` on tables from different databases
## 6. Improve the performance of your query with `EXPLAIN QUERY PLAN`

# Conclusion
