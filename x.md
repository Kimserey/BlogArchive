# Build your own Line chart for Xamarin.Forms with Custom renderers (Part 2)

Last week we saw how we could use custom renderers with boxview to draw via the canvas api ()[].

Today I will go through the steps to draw a line chart supporting markers.
The line chart is very simple and has only one objective, give a rough indication of the current trend of the data displayed.

![]()

In order to draw the chart, we will divide the chart in four layer which we will draw one by one.
Therefore this post will be composed by the four layers.

1. Draw background and bands
2. Draw axis and labels
3. Draw lines
4. Draw markers


## 1. Draw background and bands

We can see the canvas as a painting canvas.
When we draw something and then draw something on top of that, the last thing drawn will hide the previous one - just like as if you are painting something on top of something else.
Therefore the first thing we need to draw is the background.

```
// Draws background
paint.Color = Color.ParseColor("#2CBCEB");
canvas.DrawRect(new Rect(0, 0, this.Width, this.Height), paint);
```

`this.Width` and `this.Height` return respectively the view width and height.

Next we draw the bands.

In order to get the bands, we first need to know __the boundaries of the graph__.
So I defined a class called PlotBoundaries:

```
class PlotBoundaries
{
    public float Left { get; set; }
    public float Right { get; set; }
    public float Top { get; set; }
    public float Bottom { get; set; }
}
```

`Left`, `Right`, `Top` and `Bottom` represent the X axis start, X axis end, Y axis start and Y axis end of the chart.
It will be used to place the chart in the view.
Also every lines, axis, labels and markers will be drawn using the boundaries as reference.

As it is easier to understand with a picture here is a picture:

![]()

I have all my padding saved into an `options` object.
I have shown how you can access properties from the Xamarin.Forms view in my previous blog post - [](),
that's where I get the options from, if you want to see the full code please refer to my github ()[]. 

`Left` will be the padding left plus the text size and plus some small offset for the text to not be right next to the axis.

```
Left = options.Padding.Left * density + paint.MeasureText(ceilingValue.ToString()) + yAxisLabelOffset
```

`Right` will be the width minus the right padding.

```
Right = this.Width - options.Padding.Right * density
```

`Top` will be the top padding.

```
Top = options.Padding.Top * density,
```

And lastly `Bottom` will be the height minus bottom padding and minus the paint text size and minus a small offset again.

```
Bottom = this.Height - options.Padding.Bottom * density - paint.TextSize - xAxisLabelOffset
```

So the full code then becomes:

```
var plotBoundaries = new PlotBoundaries
{
    Left = options.Padding.Left * density + paint.MeasureText(ceilingValue.ToString()) + yAxisLabelOffset,
    Right = this.Width - options.Padding.Right * density,
    Top = options.Padding.Top * density,
    Bottom = this.Height - options.Padding.Bottom * density - paint.TextSize - xAxisLabelOffset
};
```
Using the boundaries we can also deduce the width and height of the plot:

```
var plotWidth = plotBoundaries.Right - plotBoundaries.Left;
var plotHeight = plotBoundaries.Bottom - plotBoundaries.Top;
```

Now that we have the boundaries, we need more information about the vertical sections.
Therefore I created a section class:

```
class Section
{
    public int Count { get; set; }
    public float Width { get; set; }
    public float Max { get; set; }
}
```
`Count` is the number of section displayed on the graph, `Width` is the width of a section and `Max` is the overall maximum value of the Y axis.

```
var verticalSection = new Section
{
    Width = plotWidth / items.Count(),
    Count = items.Count()
};
```
There are as many vertical section as there are items and the width of each section is just the plotWidth divided by the number of items.

```
var sectionCount = 4;
var ceilingValue = Math.Ceiling(items.Max(i => i.Y) / 50.0) * 50.0;

var horizontalSection = new Section
{
    Max = (float)ceilingValue,
    Count = sectionCount,
    Width = plotHeight / sectionCount
};
```

In order to have a graph that renders nicely on a defined number of sections, the maximum value must be calculated by rounding up to the closest 50.
I have set the number of section to 4 as I know that for any type of view in my usage, 4 sections is the nicest display.

Using that we can now draw the horizontal bands:

```
// Draws horizontal bands
paint.Reset();
paint.Color = bandsColor;
for (int i = horizontalSection.Count - 1; i >= 0; i = i - 2)
{
    var y = plotBoundaries.Bottom - horizontalSection.Width * i;

    canvas.DrawRect(
        left: plotBoundaries.Left,
        top: y - horizontalSection.Width,
        right: plotBoundaries.Right,
        bottom: y,
        paint: paint);
}
```

![]()

Woohoo nice! That looks like something at least.
We can already imagine our chart on top of that drawing!

Let's move to the next piece to draw __the axis and labels__.

## 2. Draw axis and labels

