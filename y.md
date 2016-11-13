# Fix INSTALL_FAILED adb server version doesn't match Xamarin.Android

Today I would like to share with you how you can fix the following problem:

```
INSTALL_FAILED
```

```
/Library/Frameworks/Mono.framework/External/xbuild/Xamarin/Android/Xamarin.Android.Common.Debugging.targets: Warning: error: could not install *smartsocket* listener: Address already in use
ADB server didn't ACK
* failed to start daemon *
error: cannot connect to daemon
List of devices attached
adb server version (32) doesn't match this client (36); killing...
```

## 1. Problem

You might be running two different ADB and the versions collide.

## 2. Solution

Verify that in  

```
About Xamarin > Show details > Android SDK: [PATH]
```

Make sure the PATH is the same as the one referenced in Genymotion.

```
Genymotion > Settings > ADB > Use custom Android SDK tools > Put PATH in Android SDK
```

This means that the adb used by Xamarin Studio to perform all deployment will be the same as the daemon used by the VM.
If you see the error above it's probably because the PATHs are different.

Once you have set the same path, your app should deploy properly.

# Conclusion

Always make sure that your ADB path is the same for Xamarin and the VM you deploy to.
If you have any question, leave a comment here or hit me Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam)!
See you next time!

# Other posts you will like!

- Build your own Line Chart for Xamarin.Forms (Part 2) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for_31.html)
- Build your own Line chart for Xamarin.Forms (Part 1) - [https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-your-own-line-chart-for.html)
- Make a splash screen in Xamarin.Android - [https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html](https://kimsereyblog.blogspot.co.uk/2016/10/how-to-make-splash-screen-with.html)
- Make an accordion view in Xamarin.Forms - [https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html](https://kimsereyblog.blogspot.co.uk/2016/10/build-accordion-view-in-xamarinforms.html)
