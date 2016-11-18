# Fix adb server is out of date killing

Last week I showed you how to fix the error `adb server version doesn't match...` with Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/11/fix-installfailed-error-adb-server.html](https://kimsereyblog.blogspot.co.uk/2016/11/fix-installfailed-error-adb-server.html) when trying to deploy an application built in Xamarin.Studio to a Genymotion VM.
This was caused by two different versions of ADB being installed on the machine.
One installed during Xamarin installation and another one installed separately.

The solution was to set the ADB path in the options of Genymotion.

## 1. Problem

I thought all was good but turns out there was another issue.
When running `adb shell`, I had the following error in bash:

```
adb server is out of date killing...
```

## 2. Solution

Again the problem was due to my machine having 2 adb versions and the path in `$PATH` was the wrong one.
In order to check this I looked at the path `echo $PATH` and saw that the path was incorrect.
My path in `~/.bash_profile` which is the script executed on each start of bash therefore I went ahead and changed it:

```
vim ~/.bash_profile
```
```
export PATH=$PATH:/Users/kimsereylam/Library/Developer/Xamarin/android-sdk-macosx/platform-tools
```

After doing that, running `adb shell` was all good! 

# Conclusion

Today we saw how we could fix `adb server is out of date killing` which was happening because of a wrong adb path in $PATH.
Make sure the location of ADB is the same in Xamarin.Studio, Genymotion and bash $PATH!
Hope this helped! If you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Other posts you will like!

- Build your own Line Chart for Xamarin.Forms (Part 2) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html)
- Build your own Line chart for Xamarin.Forms (Part 1) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html)
- Make a splash screen in Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html](https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html)
- Make an accordion view in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html)
