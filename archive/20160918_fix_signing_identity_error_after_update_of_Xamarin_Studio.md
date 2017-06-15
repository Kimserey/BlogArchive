# Fix signing identity error after update of Xamarin Studio

This post will explain how to fix the errors appearing in Xamarin Studio after recent update:

```
The version of Xamarin.iOS requires the iOS 10.0SDK when the managed linker is disabled.

Error executing task Codesign: Required property 'Sigingkey' not set.
```

I recently started to play with Xamarin.iOS and am still at the beginner level - I don't know anything about developping apps on iOS.
But so far I have been able to play around and deploy to the xcode simulator until yesterday.

Yesterday I updated Xamarin Studio and was welcomed with an error preventing me from compiling my Xamarin.iOS project.

The error said was the following:

![error image](https://github.com/Kimserey/BlogArchive/blob/master/img/signingkeyxcode/update_xcode_error.png?raw=true)

I had to do some googling and lookaround the settings to get that sorted which took me about half to an hour.
Today I would like to share that with you so that you won't need to do the search that I did.

The steps to fix this are the following:

``` 
 1. Update Xcode to latest
 2. Add an apple account to Xcode and check the iOS development setting
```

 ## 1. Update Xcode to latest

Basically what it said was that iOS 10 had something changed which required to have some sort of certificate.
I am totally unsure about the details, like I said earlier I don't know much about iOS but this error seemed to indicate that I needed to upgrade XCode.

So I went straight the App store and updated XCode.

![update xcode](https://github.com/Kimserey/BlogArchive/blob/master/img/signingkeyxcode/xcode.png?raw=true)

Once it completed I launched it to accept all the agreement and restarted Xamarin Studio.

But that was not done yet, next I was welcomed with another error message:

![error image 2](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/signingkeyxcode/sigingkey.png)

## 2. Add an apple account to Xcode and check the iOS development setting

What it said was that a `SigningKey` property was not set.
It seems like from iOS10, it is required to log in with your apple ID and create a signing identity.

__In case you wondered, yes it is free to create a signing identities - this is not related to enrollment to apple developer program.__

So first head to XCode > Preferences > Accounts > + to add account > View details > Create iOS Development.

![xcode](https://github.com/Kimserey/BlogArchive/blob/master/img/signingkeyxcode/appleid.png?raw=true)
![sigingkey](https://github.com/Kimserey/BlogArchive/blob/master/img/signingkeyxcode/iosdev.png?raw=true)

Once you restart Xamarin Studio and recompile, you should be able to publish to the simultator again.

## Done

Happy coding!
