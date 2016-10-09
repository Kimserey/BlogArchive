# What does DP, DPI, PPI and PX represent in Android?

I've been playing with Xamarin Android for a while now and one thing that disturbed me when I started was the units of measure.
__What is the difference between DP, DPI, PPI and PX in Android?__

I found my answers in the [Material design guide](https://material.google.com/layout/units-measurements.html)
and today I would like to share my undertanding of the differences and bring a different explanation which hopefully will help you get a better understanding.

This post is composed by three parts:
 
```
 1. PX - pixels
 2. DPI / PPI - pixels per inch
 3. DP - density-independent pixel
```

## 1. PX - pixels

Pixels is the most granular unit of measure.
When talking about resolution 1920x1080, 2560x1440, etc..
It represents the amount of pixels which fit in the screen.

The higher the better but __a second aspect equally important has too be taken in consideration - the screen dimension__.

Two devices with the same resolution but different screen sizes will not have the same display.
For a similar resolution, the bigger the screen, the bigger the pixel size will be - it would be as if we stretch the screen which makes each pixels look bigger.

To take the screen dimension into account, another measure was created - DPI or PPI - density per pixel also called pixel per inch.

## 2. DPI / PPI - pixels per inch

DPI and PPI represent the same thing except - pixel per inch. 
This unit helps to measure the size of a pixel.
It is an indicative of how many pixels can be found in one inch.

So the higher the density, the more pixels can be pushed into one inch.

__How does density affect the display?__

If we were to construct elements using pixels, 
the elements will appear smaller on high density devices - because many pixels are available per inch - and larger on low density devices - because not a lot of pixels are available per inch.

If we had to cater for that in the code of the Android app, it would be a nightmare so that's where __DP__ - density-independent pixel - came from.

## 3. DP - density-independent pixel

DP is the density-independent pixel unit.
__Independent pixel__ because the unit of measure is __independent of the density__, it is independent of the screen dimension and resolution.
__Whether the density is high or low, the elements on the screen will have approximatively the same size/look__.

This is very important for measures of margins and paddings as we want margins and paddings to always be consistant.

__But how does it work? How is the unit independent of the screen density?__

In order to create a unit of measure independent of the density, Android has defined multiple buckets - mdpi / hdpi / xhdpi / xxhdpi / xxxhdpi.

Each buckets represent a certain amount of DPI and have been given a label ranging from mdpi - the lowest resolution with the lowest density - up to xxxhdpi - the highest resolution with the highest density.

| Resolution | DPI | ratio|
|---------|:---:|-----:|
| xxxhdpi | 640 | 4.0 (640/160) |
| xxhdpi  | 480 | 3.0 (480/160) |
| xhdpi   | 320 | 2.0 (320/160) |
| hdpi    | 240 | 1.5 (240/160) |
| mdpi    | 160 | 1.0 (160/160) |

For each of this buckets, a __ratio__ has been attributed. Starting from __mdpi__ ratio of __1.0__ up to __xxxhdpi__ ratio of __4.0__. 
As you might have guessed, __all dpis have been normalized to mdpi__, in order words __1 px in mdpi is equivalent to 4 pixel in xxxhdpi__.
And this is the key behind DP, so let me repeat it, __1 px in mdpi is equivalent to 4 pixel in xxxhdpi__.

The formula behind it is the following:

```
px = (screen dpi / 160) * dp
```

The formula says that `to calculate the pixels, normalize the screen density (dpi/160) and time the density-independent pixels`.
Obviously you can move the variables around and get the dp in function of the px.

```
dp = (px * 160) / dpi
```

The DPI being a variable constant to the device and 160 being the normal, the whole `160/dpi` can then become a constant:

```
with K = 160 / dpi

dp = px * K 
```

And that's where DP came from, __DP is PX time a constant K which varies depending on the screen density and ensure a consistant measure accross any screen and resolution__.
By using that we can have a unit of measure consitant accross all density where `1 dp` in `mdpi` is equal to `1 dp` in `xhdpi` or in `xxxhdpi`.

# Conclusion

Today we saw where the unit DP came from. It is important to understand especially when you start dealing with drawings and canvas.
Understanding this took me a while and I hope that I made the task easier for you.
Let me know what you think by leaving a comment below or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).
See you next time!

# Other post you will like

- Make a splash screen in Xamarin.Android - []()
- Make an accordion view in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html)
- Understand the primary features of GIMP - [https://kimsereyblog.blogspot.co.uk/2016/09/gimps-primary-features.html](https://kimsereyblog.blogspot.co.uk/2016/09/gimps-primary-features.html)
- Absolute layout in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/09/absolute-layout-and-relative-layout.html](https://kimsereyblog.blogspot.co.uk/2016/09/absolute-layout-and-relative-layout.html)
