# Use Font Awesome from your Xamarin.Forms project

Icons are important in mobile applications where space is limited.
We use icon everywhere to convey action intent like `+` would be to add an item or a `bin` would be to delete one.
There are two ways to add icons to our mobile app:
1. with images
2. with fonts

Today we will see the second option - __how we can add Font awesome to our Xamarin.Android project and how we can use it from Xamarin.Forms.__
This post will be composed by three parts:
```
 1. Why font awesome
 2. Add font awesome to the Droid project
 3. Use with Xamarin.Forms
```

## 1. Why font awesome

If you are familiar with Web development, you must have encountered Font awesome [http://fontawesome.io/](http://fontawesome.io/).
It is an icon font containing lots of icon for every type of usage. 
The advantaged of using a font is that we can leverage the text options, like text color or text size, to easily update the style of the icon to match our app.

Let's see how we can bring Font Awesome to the Droid project.

## 2. Add Font awesome to the Droid project

Download Font awesome from the website [http://fontawesome.io/](http://fontawesome.io/) by clicking on the Download button.
Extract the `.ttf` from the zip and place it in __the Asset folder of the Xamarin.Android project__.
After that, you will be able to get the font using the `Typeface` api:

```
var typeface = Typeface.CreateFromAsset(Forms.Context.ApplicationContext.Assets, "fontawesome-webfont.ttf");
```

Which we can then set to a `TextView` in Android:

```
((TextView)control).Typeface = typeface;
```

_This works for all fonts including fontawesome._

Now that we know how to use a custom font, let's see how we can use it from Xamarin.Forms.

## 3. Use it from Xamarin.Forms

To use the custom font, we can use a `CustomRenderer` and override the `Label` control from Xamarin.Forms.

We start by creating a subclass of the label control.

```
// Used for custom rendering
public class IconLabel : Label { }
```

We will use this class as an indicator that the label is meant to be used with Font awesome font.

Next we create the renderer in the `Droid` project.

```
[assembly: ExportRenderer(typeof(IconLabel), typeof(IconRenderer))]
namespace Droid
{
	public class IconRenderer: LabelRenderer
	{
		protected override void OnElementChanged(ElementChangedEventArgs<Label> e)
		{
			base.OnElementChanged(e);
			var label = (TextView)Control;
			var font = Typeface.CreateFromAsset(Forms.Context.ApplicationContext.Assets, "fontawesome-webfont.ttf");
			label.Typeface = font;
		}
	}
}
```

After we've done this, every time we use the IconLabel, the renderer will be invoked and font awesome will be used as font family for the label.

Lastly, Font Awesome does not use the common keyboard characters for its icons, it uses special unicode characters.
The full list can be found here [http://fontawesome.io/cheatsheet/](http://fontawesome.io/cheatsheet/). 
So what we need to do is to choose the characters which correspond to the icons we need to use and pass it as text of the label.

```
var fileO = '\xf0f6';

var icon = new IconLabel
{
    Margin = new Thickness(0, 2, 0, 0),
    Text = fileO.ToString()
};
```

Notice `\xf0f6` is the unicode character found for `file-o` in the cheatsheet.
Now if we run our application, we should be able to see the icons display! Victory!

![https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20161230_fontawesome_xamarinforms/screenshot.png](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20161230_fontawesome_xamarinforms/screenshot.png)

[Full source code available here - https://github.com/Kimserey/CustomFonts](https://github.com/Kimserey/CustomFonts)

# Conclusion

Today we saw how we could use Font Awesome icon font in our Android application using Xamarin.Forms. Using fonts is a very easy way to get icons on your app with the correct color and size since the text color and font size is directly supported by Xamarin.Forms. Hope you liked this post, if you have any questions leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Other you will like

- Transform an activity asynchronous event to an awaitable task for Xamarin.Forms services - [http://kimsereyblog.blogspot.com/2016/12/transform-operation-from-xamarinandroid.html](http://kimsereyblog.blogspot.com/2016/12/transform-operation-from-xamarinandroid.html)
- Understand the difference between Internal and External folder storage in Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html](https://kimsereyblog.blogspot.co.uk/2016/11/differences-between-internal-and.html)
- Use the Snackbar API with Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html](https://kimsereyblog.blogspot.co.uk/2016/11/how-to-use-snackbar-api-in.html)
- Build your own Line Chart for Xamarin.Forms (Part 2) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html)
- Build your own Line chart for Xamarin.Forms (Part 1) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html)

# Support me
[Support me by visting my website](https://www.kimsereylam.com). Thank you!

[Support me by downloading my app BASKEE](https://www.kimsereylam.com/baskee). Thank you!

![baskee](https://raw.githubusercontent.com/Kimserey/kimserey.github.io/master/img/readme/baskee_screenshots.png)

[Support me by downloading my app EXPENSE KING](https://www.kimsereylam.com/expenseking). Thank you!

![expense king](https://raw.githubusercontent.com/Kimserey/kimserey.github.io/master/img/readme/expenseking_screenshots.png)
