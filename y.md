# Xamarin.Android app instantly closing with error after deployment

Last week I had an issue suddenly after updating Xamarin.Android and downloading the latest Android sdk 24.

__My application kept closing instantely after being deployed showing the following error:__

![img](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20161111_crash/crash.png)

I looked online and all I found was answers which recommended to uninstall the app either through the Android settings or using `adb uninstall <package name>`, clean and rebuild __but
nothing did it__. It was still crashing.

## 1. Scoping the issue

I wasn't sure what was going on until I remembered that I could access the logs via `adb logcat`. After inspecting the logs, I saw the following error message:

```
AndroidRuntime: java.lang.RuntimeException: Unable to get provider mono.MonoRuntimeProvider: java.lang.RuntimeException: Unable to find application Mono.Android.Platform.ApiLevel_24 or Xamarin.Android.Platform!
```

It was that it couldn't find `ApiLevel_24` but my manifest was configured as followed:

```
<uses-sdk android:minSdkVersion="21" android:targetSdkVersion="23" />
```

The problem was that my VM was running API 23, the app was configured to target API 23 but somehow, when the app ran it was looking for API 24 which caused it to crash.

## 2. Fixing the issue

__The problem was in the csproj file.__

`AndroidUseLatestPlatformSdk` was set to `true` which was forcing the app to look for the latest sdk and the latest sdk I installed was 24!
After setting it to false all went well again.

You can also set it from `right click on project > Options > General > Target framework > Select your framework`.

![menu](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20161111_crash/target.png)

# Conclusion

Remember to use `adb logcat` to check the issue and make sure you are targeting the correct version of Android.
Hope this post was helpful for you! As usual if you have any comments leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).

# Other post you will like!

