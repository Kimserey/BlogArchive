# Build an accordion view in Xamarin.Forms

Few weeks ago I posted about [absolute and relative layouts](https://kimsereyblog.blogspot.co.uk/2016/09/absolute-layout-and-relative-layout.html).
Layouts are called `Layouts` because they contain children which are placed in a particular way.
Xamarin.Forms has a lot of layouts and views to structure pages like grid, table view or list view.

Today I would like to show you how we can use some of these basic views to build an __Accordion view__.

Here's a preview of the Accordion view:

![accordion](https://raw.githubusercontent.com/Kimserey/AccordionView/master/img/accordion.gif)

Full source code available on GitHub - [https://github.com/Kimserey/AccordionView](https://github.com/Kimserey/AccordionView)

This post will be composed of four steps:

 1. Create a `BindableProperty`
 2. Define the accordion expandable section
 3. Define the accordion view
 4. Usage sample

## 1. Create a `BindableProperty`

As we saw in one of my [previous post](https://kimsereyblog.blogspot.co.uk/2016/08/understand-xamarin-forms-data-bindings.html), 
Xamarin.Forms works around data bindings.
View properties are bound to viewmodel properties.

Default views like `Label`, `Button`, `ListView` or `TableView` come with the necessary bindable properties like `BackgroundColor`, `TextColor`, `ItemsSource`, `ItemTemplate`, etc...
But today we are going to create our own view so we will need to provide our own `BindableProperty`s

In order to create a `BindableProperty`, we can use the static method from the `BindableProperty` class `BindableProperty.Create(...)`.

```
public static readonly BindableProperty TitleProperty =
    BindableProperty.Create(
        propertyName: "Title",
        returnType: typeof(string),
        declaringType: typeof(AccordionSectionView),
        propertyChanged: AccordionSectionView.ChangeTitle);
```

`Create(...)` takes as argument:
 
 - the `propertyName` which needs to match the property which will be set in the class, here `Title`
 - the `returnType` which specifies the type returned by the property, here `Title` returns a type `string`
 - the `declaringType` which specifies the type that declares the property, the class itself, here called `AccordionSectionView`
 - the `propertyChanged` which specifies a delegate to be executed when the property is changed

Here is an example of a potential `propertyChanged` delegate:

```
static void ChangeTitle(BindableObject bindable, object oldValue, object newValue)
{
    //Do something on changed
}
```

After that we have defined the `BindableProperty`, we need to define the underlying property - the property containing the concrete value.

```
public string Title
{
    get { return (string)GetValue(TitleProperty); }
    set { SetValue(TitleProperty, value); }
}
```

In order to interact with the `BindableProperty`, Xamarin.Forms provide `GetValue` and `SetValue` which gets and sets the bindable property.

## 2. Define the accordion expandable section

Now that we know how to make our own binding properties, let's start with the Accordion view.

![accordion](https://raw.githubusercontent.com/Kimserey/AccordionView/master/img/accordion.gif)

Our accordion view will be built of two parts:

 - an expandle section with a header and a list
 - an overall list which will contain the expandable sections

 We will start here by the expandable section.

 ### 2.1 The Accordion expandable section

The accordion expandable section is the item portion which contains a header and a list and can be expanded or retracted.

![expand](https://github.com/Kimserey/AccordionView/blob/master/img/accordion_section.png?raw=true)

For example, in the image above, we can see `November` section being retracted and when expanded, display a list of dates with prices.

__Where do we start?__

First thing to do is to figure out which are the bindable properties.
In order to figure this, I ask myself, __which property of the model will be needed to construct the view?__ and the answer to that usually are the bindable properties.
Here the section needs a `title` and a `list` of items which will be used to construct the content. 

The whole section can be defined as a `StackLayout` as it is basically stacking views in a vertical fashion.
For the `content`, I will also use a `StackLayout` so that everything will be visible. _This will cause performance issue if you list is potentially infinite, so you might want to use something else if it doesn't suit your needs._

With that in mind, we can write the following:

```
public class AccordionSectionView: StackLayout
{
    private Label _headerTitle = new Label { TextColor = Color.White, VerticalTextAlignment = TextAlignment.Center, HeightRequest = 50 };
    private StackLayout _content = new StackLayout { HeightRequest = 0 };
    private DataTemplate _template;

    public static readonly BindableProperty ItemsSourceProperty =
        BindableProperty.Create(
            propertyName: "ItemsSource",
            returnType: typeof(IList),
            declaringType: typeof(AccordionSectionView),
            defaultValue: default(IList),
            propertyChanged: AccordionSectionView.PopulateList);

    public IList ItemsSource
    {
        get { return (IList)GetValue(ItemsSourceProperty); }
        set { SetValue(ItemsSourceProperty, value); }
    }

    public static readonly BindableProperty TitleProperty =
        BindableProperty.Create(
            propertyName: "Title",
            returnType: typeof(string),
            declaringType: typeof(AccordionSectionView),
            propertyChanged: AccordionSectionView.ChangeTitle);

    public string Title
    {
        get { return (string)GetValue(TitleProperty); }
        set { SetValue(TitleProperty, value); }
    }

    public AccordionSectionView(DataTemplate itemTemplate, ScrollView parent)
    {
        _template = itemTemplate;
        this.Spacing = 0;
        this.Children.Add(_headerTitle);
        this.Children.Add(_content);
    }

    void ChangeTitle()
    {
        _headerTitle.Text = this.Title;
    }

    void PopulateList()
    {
        _content.Children.Clear();

        foreach (object item in this.ItemsSource)
        {
            var template = (View)_template.CreateContent();
            template.BindingContext = item;
            _content.Children.Add(template);
        }
    }

    static void ChangeTitle(BindableObject bindable, object oldValue, object newValue)
    {
        if (oldValue == newValue) return;
        ((AccordionSectionView)bindable).ChangeTitle();
    }

    static void PopulateList(BindableObject bindable, object oldValue, object newValue)
    {
        if (oldValue == newValue) return;
        ((AccordionSectionView)bindable).PopulateList();
    }
}
```

We created two `BindableProperty` and defined the `headerTitle` and the `content`.
Also we are taking a `DataTemplate` as constructor parameter to create template for the items in `content`.

```
var template = (View)_template.CreateContent();
template.BindingContext = item;
_content.Children.Add(template);
```

Now if you run this you will see the headers but __nothing happens when you click on the headers.__

### 2.2 Handle gesture

In order to handle tap gesture on the header, we need to add a `GestureRecognizer` to the header.
This is done using `GestureRecognizers.Add(new TapGestureRecognizer(...))`.

We need to add the following code in the constructor of the view:

```
_headerTitle.GestureRecognizers.Add(
    new TapGestureRecognizer
    {
        Command = new Command(async () =>
        {
            if (_isExpanded)
            {
                _content.HeightRequest = 0;
                _content.IsVisible = false;
                _isExpanded = false;
            }
            else
            {
                _content.HeightRequest = _content.Children.Count * 50;
                _content.IsVisible = true;
                _isExpanded = true;

                // Scroll top by the current Y position of the section
                if (parent.Parent is VisualElement)
                {
                    await parent.ScrollToAsync(0, this.Y, true);
                }
            }
        })
    }
);
```

I have added state indicator `_isExpanded`.
`When the section is already expanded`, it means that we want to `hide the section` therefore we `set the height to zero` and we `make the content invisible`.
`When the section is retracted`, it means that we want to `show the section` therefore we `set back the height` and `make the content visible` and also `scroll the element to the top by scrolling using the current Y position`.

_Scrolling using Y will bring the section as close as possible to the top._

### 2.3 Full Accordion expandable section

Here is the full accordion section discribed above.

```
public class AccordionSectionView: StackLayout
{
    private Label _headerTitle = new Label { VerticalTextAlignment = TextAlignment.Center, HeightRequest = 50 };
    private StackLayout _content = new StackLayout { HeightRequest = 0 };
    private DataTemplate _template;

    public static readonly BindableProperty ItemsSourceProperty =
        BindableProperty.Create(
            propertyName: "ItemsSource",
            returnType: typeof(IList),
            declaringType: typeof(AccordionSectionView),
            defaultValue: default(IList),
            propertyChanged: AccordionSectionView.PopulateList);

    public IList ItemsSource
    {
        get { return (IList)GetValue(ItemsSourceProperty); }
        set { SetValue(ItemsSourceProperty, value); }
    }

    public static readonly BindableProperty TitleProperty =
        BindableProperty.Create(
            propertyName: "Title",
            returnType: typeof(string),
            declaringType: typeof(AccordionSectionView),
            propertyChanged: AccordionSectionView.ChangeTitle);

    public string Title
    {
        get { return (string)GetValue(TitleProperty); }
        set { SetValue(TitleProperty, value); }
    }

    public AccordionSectionView(DataTemplate itemTemplate, ScrollView parent)
    {
        _template = itemTemplate;
        this.Spacing = 0;
        this.Children.Add(_headerTitle);
        this.Children.Add(_content);

        _headerTitle.GestureRecognizers.Add(
            new TapGestureRecognizer
            {
                Command = new Command(async () =>
                {
                    if (_isExpanded)
                    {
                        _content.HeightRequest = 0;
                        _content.IsVisible = false;
                        _isExpanded = false;
                    }
                    else
                    {
                        _content.HeightRequest = _content.Children.Count * 50;
                        _content.IsVisible = true;
                        _isExpanded = true;

                        // Scroll top by the current Y position of the section
                        if (parent.Parent is VisualElement)
                        {
                            await parent.ScrollToAsync(0, this.Y, true);
                        }
                    }
                })
            }
        );
    }

    void ChangeTitle()
    {
        _headerTitle.Text = this.Title;
    }

    void PopulateList()
    {
        _content.Children.Clear();

        foreach (object item in this.ItemsSource)
        {
            var template = (View)_template.CreateContent();
            template.BindingContext = item;
            _content.Children.Add(template);
        }
    }

    static void ChangeTitle(BindableObject bindable, object oldValue, object newValue)
    {
        if (oldValue == newValue) return;
        ((AccordionSectionView)bindable).ChangeTitle();
    }

    static void PopulateList(BindableObject bindable, object oldValue, object newValue)
    {
        if (oldValue == newValue) return;
        ((AccordionSectionView)bindable).PopulateList();
    }
}
```

## 3. Define the accordion view

```
public class AccordionView : ScrollView
{
    private StackLayout _layout = new StackLayout { Spacing = 1 };

    public DataTemplate Template { get; set; }
    public DataTemplate SubTemplate { get; set; }

    public static readonly BindableProperty ItemsSourceProperty =
        BindableProperty.Create(
            propertyName: "ItemsSource",
            returnType: typeof(IList),
            declaringType: typeof(AccordionSectionView),
            defaultValue: default(IList),
            propertyChanged: AccordionView.PopulateList);

    public IList ItemsSource
    {
        get { return (IList)GetValue(ItemsSourceProperty); }
        set { SetValue(ItemsSourceProperty, value); }
    }

    public AccordionView(DataTemplate itemTemplate)
    {
        this.SubTemplate = itemTemplate;
        this.Template = new DataTemplate(() => (object)(new AccordionSectionView(itemTemplate, this)));
        this.Content = _layout;
    }

    void PopulateList()
    {
        _layout.Children.Clear();

        foreach (object item in this.ItemsSource)
        {
            var template = (View)this.Template.CreateContent();
            template.BindingContext = item;
            _layout.Children.Add(template);
        }
    }

    static void PopulateList(BindableObject bindable, object oldValue, object newValue)
    {
        if (oldValue == newValue) return;
        ((AccordionView)bindable).PopulateList();
    }
}
```

## 4. Usage sample

```
public class DefaultTemplate : AbsoluteLayout
{
    public DefaultTemplate()
    {
        this.Padding = 5;
        this.HeightRequest = 50;
        var title = new Label { HorizontalTextAlignment = TextAlignment.Start, HorizontalOptions = LayoutOptions.StartAndExpand };
        var price = new Label { HorizontalTextAlignment = TextAlignment.End, HorizontalOptions = LayoutOptions.End };
        this.Children.Add(title, new Rectangle(0, 0.5, 0.5, 1), AbsoluteLayoutFlags.All);
        this.Children.Add(price, new Rectangle(1, 0.5, 0.5, 1), AbsoluteLayoutFlags.All);
        title.SetBinding(Label.TextProperty, "Date", stringFormat: "{0:dd MMM yyyy}");
        price.SetBinding(Label.TextProperty, "Amount", stringFormat: "{0:C2}");
    }
}
```

```
public class ShoppingCart
{
    public DateTime Date { get; set; }
    public double Amount { get; set; }
}

public class Section
{ 
    public string Title { get; set; }
    public IEnumerable<ShoppingCart> List { get; set; }
}

public class ViewModel
{
    public IEnumerable<Section> List { get; set; }
}
```

```
public class AccordionViewPage : ContentPage
{
    public AccordionViewPage()
    {
        this.Title = "Accordion";

        var template = new DataTemplate(typeof(DefaultTemplate));

        var view = new AccordionView(template);
        view.SetBinding(AccordionView.ItemsSourceProperty, "List");
        view.Template.SetBinding(AccordionSectionView.TitleProperty, "Title");
        view.Template.SetBinding(AccordionSectionView.ItemsSourceProperty, "List");

        view.BindingContext =
            new ViewModel
            { 
                List = new List<Section> {
                    new Section
                    {
                        Title = "December",
                        List = new List<ShoppingCart> {
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 }
                        }
                    },
                    new Section
                    {
                        Title = "November",
                        List = new List<ShoppingCart> {
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 }
                        }
                    },
                    new Section
                    {
                        Title = "October",
                        List = new List<ShoppingCart> {
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 }
                        }
                    },
                    new Section
                    {
                        Title = "September",
                        List = new List<ShoppingCart> {
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 }
                        }
                    },
                    new Section
                    {
                        Title = "August",
                        List = new List<ShoppingCart> {
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 }
                        }
                    },
                    new Section
                    {
                        Title = "July",
                        List = new List<ShoppingCart> {
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 },
                            new ShoppingCart { Date = DateTime.UtcNow, Amount = 10.05 }
                        }
                    },
                }
            };
        this.Content = view;
    }
}

public class App : Application
{
    public App()
    {
        MainPage = new NavigationPage(new AccordionViewPage());
    }
}
```

Full source code available on GitHub - [https://github.com/Kimserey/AccordionView](https://github.com/Kimserey/AccordionView)

# Conclusion

# Other post you will like!

- Steps to deploy an Android app to Play store - [https://kimsereyblog.blogspot.co.uk/2016/09/publish-your-android-app-to-google-play.html](https://kimsereyblog.blogspot.co.uk/2016/09/publish-your-android-app-to-google-play.html)
- Absolute and relative layout in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/09/absolute-layout-and-relative-layout.html](https://kimsereyblog.blogspot.co.uk/2016/09/absolute-layout-and-relative-layout.html)
- Understand data bindings in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/08/understand-xamarin-forms-data-bindings.html](https://kimsereyblog.blogspot.co.uk/2016/08/understand-xamarin-forms-data-bindings.html)
