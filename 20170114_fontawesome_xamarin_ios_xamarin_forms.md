# Use FontAwesome on your Xamarin.iOS app with Xamarin.Forms

Few weeks ago I explained how we could use FontAwesome from our Droid project link. Following the same idea, today I will explain how we can use FontAwesome on an iOS app with Xamarin.Forms.

This post is composed by three parts:

 1. Import of font into iOS project
 2. Define custom renderer
 3. Use from Xamarin.Forms

## 1. Import of font into iOS project

Import the font in .ttf format by placing it under Resources. It should then become a BundledResource. Next in Info.plist, add a new entry `Fonts provided by application` and add the path to the font from Resources folder in the values.

Once you have done this, the font should be available to use.

## 2. Define custom renderer

Similarly to the Droid project, we need to create a custom renderer and overwrite the following function:

```
 OnElementPropertyChanged(...)
```

This function is called by Xamarin when the properties of the element change. For example when the text is changed or the color is changed, the function will be called.

Xamarin.Android and Xamarin.iOS seem to behave differently in regards to text properties. Android will keep the text properties while iOS resets it. This is the reason why in the Droid tutorial I overwrote OnElementChanged instead of OnElementPropertyChanged.

In this function we will then set the font with our imported font.

```
public class IconRenderer : LabelRenderer
{
    protected override void OnElementPropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        base.OnElementPropertyChanged(sender, e);

        if (Control != null)
            Control.Font = UIFont.FromName("FontAwesome", 18);
    }
}  
```
First we do a safety check in case the Control is null then we set the Font property of the UIText using UIFont.FromName and passing the font name and the font size.

As usual, don't forget the assembly ExportRenderer attribute to declare the renderer.

```
[assembly: ExportRenderer(typeof(IconLabel), typeof(IconRenderer))] 
```

FromName expects the font name. A trick to find it is to place the following code in the AppDelegate.cs and find the name of the font in the list of fonts displayed:

```
private void ListFontName()
{
    var fontNames = UIFont
        .FamilyNames
        .SelectMany(fn => UIFont.FontNamesForFamilyName(fn).Select(font => new Tuple<string, string>(fn, font)))
        .OrderBy(i => i.Item1)
        .ThenBy(i => i.Item2);

    foreach (Tuple<string, string> font in fontNames)
    {
        Debug.WriteLine(string.Format("Font: {0}/{1}", font.Item1, font.Item2));
    }        
}
```

If your font isn't in the list, it means something went wrong in your import.

## 3. Use from Xamarin.Forms

Now that we have everything set, the Xamarin.Forms code is identical to the one in my previous post.

This is the true benefit of Xamarin.Forms. Cross platform code where we can tap on native api for custom rendering on different platforms.

And that's it!

[Full source code available here](https://github.com/Kimserey/FontTest/tree/master/iOS)

# Conclusion

Today we saw how we could use FontAwesome with Xamarin.iOS and exploit the same code as we built when making the FontAwesome for Droid blog post. We can see how we could leverage the power of Xamarin.Forms when it comes to coding a solution which will run on multiple platforms. Hope you liked this post! If you have any questions, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Other posts you will like

- Get started with SQLite in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2017/01/get-started-with-sqlite-in-from.html](https://kimsereyblog.blogspot.co.uk/2017/01/get-started-with-sqlite-in-from.html)
- Use Font awesome from your Xamarin.Android app - [https://kimsereyblog.blogspot.co.uk/2016/12/use-font-awesome-from-your-xamarinforms.html](https://kimsereyblog.blogspot.co.uk/2016/12/use-font-awesome-from-your-xamarinforms.html)
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
