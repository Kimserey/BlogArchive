Line PART 2

Last week we saw how we could use custom renderers with boxview to draw via the canvas api.

Today I will go through the steps to draw a line chart supporting markers.
The line chart is very simple and has only one objective, give a rough indication of the current trend of the data displayed.

Picture

Because the chart is so simple, it is very easy for users to understand what is going on and understand the type of interaction available.
Here only a simple touch on points is supported.

This post is composed by two parts:

1. Calculation of the measurements
2. Draw with canvas

1. Draw background and bands
2. Draw axis and labels
3. Draw lines
4. Draw markers

1. Calculcation of measurements

In order to have a good graph, we need one that is responsive. Responsive in the sense that depending on the height and width offered to draw the graph, it will draw it properly within the boundaries. Another important point is that it needs to be density independant. This is achieved using dp instead of px as unit if measure. If you arent familiar with that you can refer to my previous blog post.

So let's start first by calculating all the measurements.

Image here draw

First we need the boundaries of the graph.

Graph axis
Left
Padding + text size + text padding

Right
Padding

Top
Padding

Bottom
Padding + text height

Having that we can then calculate height in device

Bottom - top

Remember 0.0 is on the top left corner.

We want to have 4 sections therefore we want to be able to divide the graph in four

So we take the highest value, divide by four > round up > time 4 and you get the closest highest number which can be divided by four.

Now that we have the boudary and thr sections we can now draw the bands.

One we drew the band, we can draw the axes as well.

Align the text middle and draw at the middle of each section

1. Overall padding
2. Text height
3. Text length

2. Draw with canvas

As we saw in the previous post, canvas exposes some draw methods.
The chart being composed by lines, circles for the points and rectangles for the background, we will only be using DrawLine DrawCircle and DrawRect.
