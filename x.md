# Data exploration with Deedle

Data exploration is the process of taking data and manipulating it in such a way that it is workable with.
Real life data rarely come in a format exploitable for analysis, this is why data exploration is a necessary step.
It involves taking data from CSVs or databases, renaming, categorizing, reordering, transposing or pivoting tables and data.
Without any tools or libraries, it would be a pain to do these common operations.

`Deedle` is a library which simplifies data exploration by providing functions to execute common manipulation on dataframes and timeseries.

As I already went through how to get started with `Deedle` in a previous tutorial [https://kimsereyblog.blogspot.co.uk/2016/04/a-primer-on-manipulating-data-frame.html](https://kimsereyblog.blogspot.co.uk/2016/04/a-primer-on-manipulating-data-frame.html),
today I would like to show more functionalities of `Deedle` and how they can be used in a real life scenario.

This post is composed by three parts:
 1. A reminder on what is a Deedle Frame
 2. Common statistical calculations
 3. Pivot table

## 1. A reminder on what is a Deedle Frame and Series

Deedle works with the concept of dataframe and series.
A dataframe is a table which can contain elements of different type (they are cast as `obj`).

### 1.1 Frame

The type of a frame is `Frame<R, C>` where `R` is the type of the __row key__ and `C` is the type of the __column name__.
Do not confuse it with the type of the content of the cells.

Using the frame, you can get the rows in two ways `Frame.rows` and `Frame.getRows`.
The difference is that one returns `RowSeries` and the other one returns a `Series<R, Series<C, T>>` where `T` is the type of your data.

I tend to ues `Frame.rows`. `Frame.rows` transform your frame into a `RowSeries<R, C>`. It is more practical as we don't need to care about the individual type of each `Series`.
In fact there is a special type for `Series` where the content is of type `obj`; `OjectSeries<K>` where `K` is the __key type__.

The functionalities that I use the most are:

```
Frame.filterRowValues
Frame.fillMissingWith
Frame.mapRowValues
```

### 1.2 Series

The type of a series is `Series<K,V>` where `K` is the type of the __key__ and `V` is the type of the __value__.
This is important to understand; frame type constraints to not include the type of the content whereas series type constraints contain the type of the content.

As mentioned earlier, there is also `ObjectSeries<K>` where `K` is the type of the __key__ and all content is obj.
`ObjectSeries` is returned when using `Frame.rows`.



## 2. Common statistical calculations

Stats
MapValues Stats.Level
Expending mean

## 3. Pivot table

Pivot table is one of the killer feature of Deedle.
`pivotTable` allows you to produce a new frame by grouping cells based on predicate applied on rows and columns.




