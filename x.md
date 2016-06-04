# What I have learnt on SQLite

For the past few days, I have been writing a lot of `SQL` queries to query `SQLite` databases.
I had to extract data for reporting from `SQLite` databases where `SELECT-FROM-WHERE` queries weren't enough.
From that experience, I learnt few tricks that I am sure some of you will be interested in.
So today, I will list it all in this blog post.

This post is composed by five parts:

1. Use the built in date functions
2. Cast your string to integer with `CAST`
3. Transpose a table using `CASE` and `GROUP BY`
4. Attach databases to `JOIN` on tables from different databases
5. Improve the performance of your query with `EXPLAIN QUERY PLAN`


## 1. Use the built in date functions

### 1.1 strftime

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

##3. Transpose a table using `CASE` and `GROUP BY`

In one the database I had to work, the value were stored in three columns `id`, `key` and `value`.
This table gathers all the data sent from a form from our app.
`id` is the identifier of the form, `key` is the key of the field and `value` is the value of the field.

_If you are thinking why is the table designed this way, it is meant to handle the dynamic nature of the forms. 
Fields can be added or removed every day, depending on client requirements, so it would not be possible to use the field `keys` as table columns._

Storing the values this way makes it difficult to query directly.
What we need to do is to `transpose` the tabe.

```
SELECT 
    mp.id,
    mp.user_id AS userId,
    CAST (strftime('%Y', DATETIME(mp.storage_timestamp / 10000000 - 62135596800, 'unixepoch')) AS interger) AS year,
    MAX(CASE WHEN mpv.key = 'nino' THEN mpv.value END) AS nino,
    SUM(CASE WHEN mpv.key = 'support-duration-hours' THEN mpv.value END) AS 'support-hours',
FROM metaform_postbacks mp
JOIN metaform_postback_values mpv ON mp.id = mpv.id
GROUP BY mp.id
```

##5. Attach databases to `JOIN` on tables from different databases
##6. Improve the performance of your query with `EXPLAIN QUERY PLAN`

# Conclusion
