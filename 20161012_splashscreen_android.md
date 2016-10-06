# How to make a splash screen with Xamarin.Android

The first time I had to implement a splash screen for a Xamarin.Android app, I was completely lost.
Xamarin official documentation is great [https://developer.xamarin.com/guides/android/user_interface/creating_a_splash_screen/](https://developer.xamarin.com/guides/android/user_interface/creating_a_splash_screen/)
but without prior knowledge in Android, it is hard to follow.

So today I would like to show you how you can create a splash screen for an Xamarin.Android app and provide more explicit information on what is happening and why is it done this way.
This post is composed by 3 parts.

```
 1. What's a splash screen
 2. Implement the splash screen
 3. Use the splas screen
```

A full sample is available on my GitHub [https://github.com/Kimserey/FileFoldersXamarin/tree/master](https://github.com/Kimserey/FileFoldersXamarin/tree/master).

## 1. What's a splash screen

A splash screen is a loading screen. It is the first screen which shows up when the application launch and while it is loading.
Xamarin.Forms application do take few seconds before being loaded, therefore it is important to provide a splash screen.

Here's an example of a splash screen I created for an app that I am building - Baskee:

![splash](https://raw.githubusercontent.com/Kimserey/FileFoldersXamarin/master/splash.png)

It will be displayed until the app gets fully loaded.

A splash screen is nothing more than a activity with a display.
It has to be quick in order to show something to the user therefore the preferred way - which is the one demonstrated by Xamarin - 
is to __have a drawable image loaded as the background style of the main launching activity__.

Let's see how it works.

## 2. Implement the splash screen

As we said above, the preferred way is to __have a drawable image loaded as the background style of the main launching activity__.

```
 1. Have a drawable image
 2. Load it as a background style
 3. Bind the theme to the main launching activity
```

### 2.1 Have a drawable image

A [drawable](https://developer.android.com/guide/topics/resources/drawable-resource.html) is a resource which can be drawn to the screen.
It can be an image `bitmap` but it can also be a `xml`.

For the splash screen we will use the `layer-list`. 
A `layer-list` is a list where items are drawn one by one.

First let's start by adding a `colors.xml` file to the `values` folder.

```
<?xml version="1.0" encoding="utf-8"?>
<resources>
	<color name="white">#FFFFFF</color>
</resources>
```

Adding resources to the `values` folder will allow us to reference the color using `@color/white`.

Then add your `splash` image (`ic_pets_black_24dp` for me) and the `splash.xml` drawable, both, in the `drawable` folder. 

```
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
	<item>
		<color android:color="@color/white"/>
	</item>
	<item>
    	<bitmap
	        android:src="@drawable/ic_pets_black_24dp"
	        android:tileMode="disabled"
	        android:gravity="center"/>
	</item>
</layer-list>
```

Here the white color will be drawn first and then the `ic_pets_black_24dp` image will be drawn on top of the white background.
What we did here is that we create a `drawable` resource which will show a dog palm on top of a white background - this will be our example splashscreen.

The power of that is that since it is a `drawable`, we can use it as background. So let's do that.

### 2.2 Load it as a background style

Because the `splash.xml` is a drawable, we can use it as background of a style.

We first add a `style.xml` in the `values` folder:

```
<resources>
  <style name="Splash">
    <item name="android:windowNoTitle">true</item>  
    <item name="android:windowBackground">@drawable/splash</item>
  </style>
</resources>
```

This style resource define the style of the Splash Activity. It sets the `windowNoTitle` to true so that we won't see the action bar and it sets the `windowBackground` to our own `splash drawable`.
Thanks to the name, we will be able to reference the style using `@style/Splash`.

Now that we have the style, all we need to do is use it in an Activity.

## 3. Bind the theme to the main launching activity

All we have left to do is to create an activity which will show te splash screen and transition to the main activity

```
[Activity(MainLauncher = true, Theme = "@style/Splash", NoHistory = true)]
public class SplashActivity : Activity
{
    protected override void OnResume()
    {
        base.OnResume();

        Task.Run(() =>
        {
            StartActivity(new Intent(Application.Context, typeof(MainActivity)));
        });
    }
}
```

We set the `MainLauncher` to true and set the `Theme` to our splash theme `@style/Splash`.
We also set `NoHistory` to true so that the splash will not be part of the history - otherwise it will be possible to press back button and return to the splash screen.

Lastely in the `OnResume` function, we start a task which transition to the MainActivity while the splash is visible.

And that's it! I have push an example on GitHub if you wish to have a look - [https://github.com/Kimserey/FileFoldersXamarin/tree/master](https://github.com/Kimserey/FileFoldersXamarin/tree/master)

# Conclusion

Today we saw how we could implement a splash screen in Xamarin.Android.
It is interesting because it touches multiples aspects of an Android application.
We saw how we could create an xml drawable, how we could create a style to use the drawable as background and finally we saw how we could create an activity (splash activity) which transitions to another activity (application).
As always, if you have any comments leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).
See you next time!

# Other posts you will like!

- Publish an Android app to Play store - [https://kimsereyblog.blogspot.co.uk/2016/09/publish-your-android-app-to-google-play.html](https://kimsereyblog.blogspot.co.uk/2016/09/publish-your-android-app-to-google-play.html)
- Build an accordion view in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html)
- Understand absolute and relative layout in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/09/absolute-layout-and-relative-layout.html](https://kimsereyblog.blogspot.co.uk/2016/09/absolute-layout-and-relative-layout.html)
- Understand data bindings in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/08/understand-xamarin-forms-data-bindings.html](https://kimsereyblog.blogspot.co.uk/2016/08/understand-xamarin-forms-data-bindings.html)
- Use webview to transform website to Android app - [https://kimsereyblog.blogspot.co.uk/2016/05/transform-your-websharper-web-app-into.html](https://kimsereyblog.blogspot.co.uk/2016/05/transform-your-websharper-web-app-into.html)
