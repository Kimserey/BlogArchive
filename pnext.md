# Manage your expenses with Deedle in FSharp

The first time I encountered Deedle was from [@brandewinder](https://twitter.com/brandewinder) book [Machine learning projects for .NET developers](https://www.amazon.co.uk/Machine-Learning-Projects-Developers/dp/14302676740).
Deedle is a library which facilitates the manipulation of data frames and data series.

[http://bluemountaincapital.github.io/Deedle/](http://bluemountaincapital.github.io/Deedle/)

A data frame is like a table with rows and columns where columns don't need need to be of same type.
A data series is like a vector (an array of values) where each value is itself a key value pair.
A very famous data series is a time series which is a vector of value with a key representing an instant in time and a value associated with it (it isn't limited to this single property).

Although Deedle website contains very good tutorials, like the [Deedle in 10 minutes](http://bluemountaincapital.github.io/Deedle/tutorial.html) tutorial, I still found it a bit hard to grasp.

__So why would you need Deedle?__

One of the reason why I think Deedle is interesting is that it makes the manipulate of data frame much more pleasant.
It is possible to goup by rows, and more importantly group on multiple levels.
We can then work effectively on a certain level of the frame.
It allows to change values from a row or values from a column easily.
It is also possible to drop and add columns which is very helpful to add label or category column.
And lastely it is possible to take out the data and plot it into a graph.

I started to look at Deedle by making very basic operations.
Even after reading all the information on Deedle website, it took me few hours to put together the operations so I wanted to share that with you so that hopefully you would not take as long as I did.
In this post I played with my bank statements data.
I will explain some common operations and simple operations which will help to understand how Deedle works:

1. Extract data from CSV and load into frame
2. Label data in a new column
3. Group data by date
4. Group by label then by date and sum the amounts
5. Group by using a value constructed from a key

When you will be done with this, you will be able to have a good understanding on how to use the library in your advantage to make more complex operations.
Let's start by loading data from CSV.

## 1. Extract data from CSV and load into frame

```
type Expense = {
    Date: DateTime
    Title: string
    Amount: decimal
}

let frame =
    Directory.GetFiles(Environment.CurrentDirectory + "/data","*.csv")
    |> Array.map (fun path -> Frame.ReadCsv(path, hasHeaders = false))
    |> Array.map (fun df -> df |> Frame.indexColsWith [ "Date"; "Title"; "Amount" ])
    |> Array.map (fun df -> df.GetRows())
    |> Seq.collect (fun s -> s.Values)
    |> Seq.map (fun s -> s?Date, s?Title, s?Amount)
    |> Seq.map (fun (date, title, amount) -> 
        { Date = string date |> DateTime.Parse
          Title = string title
          Amount = string amount |> decimal })
    |> Frame.ofRecords
```

I start first by getting all the `csv` files in `/data` folder.
Then I load each file in a `Frame` using `Frame.ReadCsv`.
Because my `csv` has no header, when the frame gets loaded it has generic column names `Column 1`, `Column 2` and `Column 3`.
Therefore I use `Frame.indexColsWith` to specify my own column keys.
Then I collect all values and parse it to the correct type and then concatenate all values together in a single dataframe.

##2. Label data in a new column

Adding new column is very helpful. In my bank statement I have data like that:

```
2016-01-20,INT'L YYYYYYYYYY Amazon UK Retail AMAZON.CO.UK,-3.99
2016-01-18,INT'L XXXXXXXXXX Amazon UK Marketpl,-3.99
```

All I really care is that it comes from Amazon. I don't really care the it has a reference of X or Y.
So what I will is to add a fourth column which will contain a label which represents the store.
For the two records it will be Amazon.
At the same time I want to have a fifth column which will represent the category.
Amazon will be under `Online` which stands for online purchases.

So how will we do that?
We will use a regex pattern to match all titles and derive a label and category out of it.

```
type Category =
| DepartmentStore
| Supermarket
| AsianSupermarket
| Clothing
| Restaurant
| Electronics
| FastFood
| SweetAndSavoury
| HealthAndBeauty
| Online
| Cash
| Other

let labelStore =
    let label regex label category (str, initialCategory) =
        if Regex.IsMatch(str, regex, RegexOptions.IgnoreCase) 
        then (label, category)
        else (str, initialCategory)
        
    label    ".*Amazon.*" "AMAZON" Online
    >> label ".*ALDI.*"   "ALDI"   Supermarket
```

As an example, I have added two categories and two labels. When we pass a title with a default `Other` category, it will try to match any of the regex patterns and return the appropriate pair.
If nothing match, it will just return the value which was passed without changing anything.

So if we pass `INT'L YYYYYYYYYY Amazon UK Retail AMAZON.CO.UK` we will get `(AMAZON, Online)`.
If we pass `ALDI GR KENT` we will get `(ALDI, Supermarket)`.

Then using that pair we can create the two new columns for the data frame.

```
let df = 
    let frame =
        Directory.GetFiles(Environment.CurrentDirectory + "/data","*.csv")
        |> ... code for loading frame (explained above) ...
        |> Frame.ofRecords

    frame.AddColumn(
        "Label", 
        frame
        |> Frame.getCol "Title" 
        |> Series.mapValues ((fun title -> (title, Other)) >> labelStore >> fst))
        
    frame.AddColumn(
        "Category", 
        frame 
        |> Frame.getCol "Title" 
        |> Series.mapValues ((fun title -> (title, Other)) >> labelStore >> snd >> string))
    frame
```

We use `AddColumn` to append a column to the current frame.
We can give a title and we build this column by mapping all values per from the title column then taking the first value from the pair for the label and the second value for the category.

Now we should get the following:

```
Date        Title                                           Amount  Label   Category
2016-01-20  INT'L YYYYYYYYYY Amazon UK Retail AMAZON.CO.UK  -3.99   AMAZON  ONLINE
2016-01-18  INT'L XXXXXXXXXX Amazon UK Marketpl             -3.99   AMAZON  ONLINE
```

We successfuly categorised our data.

## 3. Group data by date
