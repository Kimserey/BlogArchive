# Data exploration with Deedle

Data exploration is the process of taking data and manipulating it in such a way that it is workable with.
Real life data rarely come in a format exploitable for analysis, this is why data exploration is a necessary step.
It involves taking data from CSVs or databases, renaming, categorizing, reordering, transposing or pivoting tables and data.
Without any tools or libraries, it would be a pain to do these common operations.

`Deedle` is a library which simplifies data exploration by providing functions to execute common manipulation on dataframes and timeseries.

As I already went through how to get started with `Deedle` in a previous tutorial.

[https://kimsereyblog.blogspot.co.uk/2016/04/a-primer-on-manipulating-data-frame.html](https://kimsereyblog.blogspot.co.uk/2016/04/a-primer-on-manipulating-data-frame.html).

Today I would like to show more functionalities of `Deedle` and how they can be used in a real life scenario.

This post is composed by three parts:
 1. A reminder on what is a Deedle Frame
 2. Common statistical calculations
 3. Pivot table

## 1. A reminder on what is a Deedle Frame and Series

Deedle works with the concept of dataframe and series.
A dataframe is a table which can contain elements of different type (held as `obj`).

### 1.1 Frame

The type of a frame is `Frame<R, C>` where `R` is the type of the __row key__ and `C` is the type of the __column name__.
Do not confuse it with the type of the content of the cells.

Using the frame, you can get the rows in two ways `Frame.rows` and `Frame.getRows`.
The difference is that one returns `RowSeries` and the other one returns a `Series<R, Series<C, T>>` where `T` is the type of your data.

I tend to ues `Frame.rows`. `Frame.rows` transform your frame into a `RowSeries<R, C>`. It is more practical as we don't need to care about the individual type of each `Series`.
In fact there is a special type for `Series` where the content is of type `obj`; `ObjectSeries<K>` where `K` is the __key type__.

Here are the functionalities I use the most with Frame.

#### Frame.filterRowValues

```
 expenses
|> Frame.filterRowValues(fun c -> c.GetAs<string>("Category") = "Supermarket")
```

Takes a function as parameter which takes the row `ObjectSeries<C>`, where `C` is the column type, as input and filter all rows for which the function return true.

#### Frame.fillMissingWith

```
expenses
|> Frame.fillMissingWith 0.
```

Fills all the missing values with the value provided.

#### Frame.getCol - Frame.getNumericCols

```
expenses
|> Frame.getCol "Title"

expenses
|> Frame.getNumericCols
```

`getCol` gets a particular column and returns a series. `getNumericCols` gets all the numeric columns and drop all other columns.
It has the advantage of making the whole frame content of type `float`.

#### Frame.groupRowsByString - Frame.groupRowsByUsing

```
expenses
|> Frame.groupRowsByString "Category"

expenses
|> Frame.groupRowsUsing(fun _ c ->  monthToString (c.GetAs<DateTime>("Date").Month) + " " + string (c.GetAs<DateTime>("Date").Year))
```

`groupRowsByString` groups the frame by a column where the content is of type `string`.
`groupRowsUsing` groups the frame using a predicate which takes as input the __row key__ and the row as a `ObjectSeries<C>` where `C` is the type of the __column key__.

### 1.2 Series

The type of a series is `Series<K,V>` where `K` is the type of the __key__ and `V` is the type of the __value__.
This is important to understand; frame type constraints to not include the type of the content whereas series type constraints contain the type of the content.

As mentioned earlier, there is also `ObjectSeries<K>` where `K` is the type of the __key__ and all content is obj.
`ObjectSeries` is returned when using `Frame.rows`.

Here are the functionalities I use the most with Series.

#### Series.mapValues

```
amounts
|> Series.mapValues (fun amount -> Math.Abs amount) 
```
#### Series.dropMissing

```
amounts
|> Series.dropMissing
```

#### Series.observations

```
amounts
|> Series.observations
```

## 2. Common statistical calculations

Stats
MapValues Stats.Level
Expending mean

## 3. Pivot table

Pivot table is one of the killer feature of Deedle.
`pivotTable` allows you to produce a new frame by grouping cells based on predicate applied on rows and columns.




