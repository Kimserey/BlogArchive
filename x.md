# Build your own Line chart for Xamarin.Forms with Custom renderers (Part 1)

Last week I needed a line chart to plot expenses.
I had two choices: use an existing library or draw the chart myself on canvas.

__I decided to go for the second - draw the chart using the Android Canvas API.__
__I chose this approach because it gives me full flexibility to create a style and behaviour that match perfectly my application.__

Here's the chart result:

![chart](https://raw.githubusercontent.com/Kimserey/GraphTest.Droid2/master/img/chartgif.gif)

This tutorial will be composed by four points divided in two parts:

```
1. Xamarin.Forms custom renderer (Part 1)
2. Explore the Android Canvas API (Part 1)
3. Create a GraphView which will draw a line chart (Part 2)
4. Use it (Part 2)
```

## 1. Xamarin.Forms custom renderer

Officiel documentation: 
[https://developer.xamarin.com/guides/xamarin-forms/custom-renderer/](https://developer.xamarin.com/guides/xamarin-forms/custom-renderer/)

A custom renderer is a class used by Xamarin.Forms to define platform specific behaviours of your views.
In this tutorial, __we will be using a custom renderer to access the Android native Canvas API to draw a line chart using data given by a view defined in a cross-platform project Xamarin.Forms__.

### 1.1 BoxRender

Let's see how we can make a custom renderer to access the Canvas API of a `BoxView`.

First, create a class which inherit from a `BoxView`, here `MyBoxView`, in the shared project.

```
namespace BoxRendererTest
{
	public class MyBoxView: BoxView
	{
		public MyBoxView() { }
	}
}
```

Then in the Android project, create a renderer by inheriting from `BoxRenderer` and specifying the `ExportRenderer` assembly attribute.

```
[assembly: ExportRenderer(typeof(MyBoxView), typeof(MyBoxViewRenderer))]
```

`BoxRenderer` gives us access to native functions of the view.
Here we override `OnDraw` which is called to draw the view to the canvas and draw a red rectangle.

```
[assembly: ExportRenderer(typeof(MyBoxView), typeof(MyBoxViewRenderer))]
namespace MyBoxViewTest.Droid
{
	public class MyBoxViewRenderer: BoxRenderer
	{
		Paint paint = new Paint { Color = Android.Graphics.Color.Red };

		protected override void OnDraw(Canvas canvas)
		{
			canvas.DrawRect(new Rect(0, 0, 100, 100), paint);
			base.OnDraw(canvas);
		}
	}
}
```

![box](https://raw.githubusercontent.com/Kimserey/GraphTest.Droid2/master/img/purple_box.png)

### 1.2 Databinding with Custom renderer

The power of Xamarin.Forms resides in its databinding system.
In order to use databindings with custom renderer, you will need to create your own property.

For our `MyBoxView`, we will create a `BoxColor` property binding.
If you aren't familiar with creating bindings, you can refer to my previous post:
[https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html)
 `1 - Create a BindableProperty`.

Here we create a bindable property called `BoxColor` which we will use to color the small rectangle drawn in the previous section.

```
public class MyBoxView : BoxView
{
    public static readonly BindableProperty BoxColorProperty =
        BindableProperty.Create(
            propertyName: "BoxColor",
            returnType: typeof(Color),
            declaringType: typeof(MyBoxView),
            defaultValue: Color.Transparent);

    public Color BoxColor
    {
        get { return (Color)GetValue(BoxColorProperty); }
        set { SetValue(BoxColorProperty, value); }
    }
}
```

And here's how we can use the property value from within the custom renderer:

```
[assembly: ExportRenderer(typeof(MyBoxView), typeof(MyBoxViewRenderer))]
namespace MyBoxViewTest.Droid
{
	public class MyBoxViewRenderer: BoxRenderer
	{
		Paint paint = new Paint();

		protected override void OnElementPropertyChanged(object sender, PropertyChangedEventArgs e)
		{
			base.OnElementPropertyChanged(sender, e);

			if (e.PropertyName == MyBoxView.BoxColorProperty.PropertyName)
			{
				this.Invalidate();
			}
		}

		protected override void OnDraw(Canvas canvas)
		{
			paint.Color = ((MyBoxView)this.Element).BoxColor.ToAndroid();
			canvas.DrawRect(new Rect(0, 0, 100, 100), paint);
			base.OnDraw(canvas);
		}
	}
}
```

`OnElementPropertyChanged` will be called when a property changes,
then we can check if the property changed is the `BoxColor` by doing `e.PropertyName == MyBoxView.BoxColorProperty.PropertyName`.
If it is, we call `Invalidate()` which __tells Android to redraw the view__ and OnDraw will be call again.
When `OnDraw` is called, we get the property from the view by using the `this.Element` property which contains the `Xamarin.Forms` element `MyBoxView` and get the color out of it.
I need to call `ToAndroid` because the color is a `Xamarin.Forms.Color` and needs to be transformed to an `Android.Graphics.Color`.

### 1.3 Hardware acceleration

Another important point is that if you don't need older version of Android, make sure to set the minimum Android version to higher than API 14 to take advantage of the hardware acceleration.
Without hardware acceleration, a typical symptom is the view's `OnDraw` gets called even when other views are changing and not the view itself.
This is very costly as we are going to draw a line chart. For example if you have a list view below your chart and a cell needs to be redrawn, without hardware acceleration, the graph will be redrawn too.
With hardware acceleration only views which are invalidated get redrawn.

## 2. Explore the Android Canvas API

```
Paint paint = new Paint();
EventHandler<TouchEventArgs> handler;
float x;
float y;

protected override void OnElementChanged(ElementChangedEventArgs<BoxView> e)
{
    base.OnElementChanged(e);

    if (handler == null) {
        handler = (sender, touchEvent) => {
            x = touchEvent.Event.GetX();
            y = touchEvent.Event.GetY();
            this.Invalidate();
        };
        this.Touch += handler;
    }
}

protected override void OnDraw(Canvas canvas)
{
    base.OnDraw(canvas);
    var density = Resources.DisplayMetrics.Density;

    // Draws a Green rectangle 100x100 at 0,0
    paint.Color = Color.Green;
    canvas.DrawRect(new RectF(0, 0, 100 * density, 100 * density), paint);

    // Saves canvas before executing clipping
    // Clips canvas to only draw in 50x100 at 50,50
    canvas.Save();
    canvas.ClipRect(new RectF(50 * density, 50 * density, 100 * density, 150 * density));

    // Draws a Red rectangle 100x100 at 50,50
    // Only 50x100 is drawn because the canvas is previously clipped at 50x100
    paint.Color = Color.Red;
    canvas.DrawRect(new RectF(50 * density, 50 * density, 150 * density, 150 * density), paint);

    // Restore canvas to before executing clipping
    // Translate canvas to 150x100
    // Draws a Blue rectangle 200x200 a 0,0 (translated)
    canvas.Restore();
    canvas.Translate(150 * density, 100 * density);
    paint.Color = Color.Blue;
    canvas.DrawRect(new RectF(0, 0, 200 * density, 200 * density), paint);


    // Draws touch coordinates
    canvas.Restore();
    canvas.Translate(-150 * density, -100 * density);
    paint.TextAlign = Paint.Align.Center;
    paint.TextSize = 14f * density;
    paint.Color = Color.Black;
    canvas.DrawText(x.ToString("F2") + "," + y.ToString("F2"), Width / 2f, Height - 5f * density, paint);
}
```


# Conclusion

# Other post you will like!
