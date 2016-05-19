# Setup your environment to build an Android app with Xamarin.Forms in F#
## From VMare Windows running on OSX

Sometime setting up a development environment is enough to discourage developers to experiment certain platforms.
Most of us (if not all of us) in .NET already heard of Xamarin.
But to start working on Xamarin, you need to setup an Android VM and setup the IDE in order to deploy on the Android VM.
And it gets worse if, like me, you run Windows on VMWare on OSX (and you want to code in F#).
Few months back, Xamarin was kind of a _no-no_ for indie development due to the pricing.
But since it merged with Microsoft, it is now free! 
It means development with Visual Studio does not require a business license anymore and we can now develop Xamarin.Forms libraries in F# easily!

Last week I started to explore Xamarin.Forms through Android. 
So before I forget how I setup the environment, I wanted to document it by sharing it with you in this post.

__How to start building Android app with Xamarin.Forms when working on Windows booted from VMWare and deploy to Xamarin Android Player on OSX?__

We will be following four steps to get everything working:
1. Download Xamarin on Windows (and Visual Studio if you don't have it)
2. Download Xamarin Android Player on OSX
3. Establish a connection between your Windows VM and the Xamarin Android Player
4. Start working on your App

## 1. Download Xamarin on Windows (and Visual Studio if you don't have it)

Xamarin on Windows: [https://developer.xamarin.com/guides/android/getting_started/installation/windows/](https://developer.xamarin.com/guides/android/getting_started/installation/windows/)

Xamarin already has a detailed installation process to [get running on Windows](https://developer.xamarin.com/guides/android/getting_started/installation/windows/).
Go to the page, download the installer and follow the process.
After that you should have the Visual Studio templates,

![templates](https://4.bp.blogspot.com/-FSIHM8HPHUU/VzwgjufcSnI/AAAAAAAAAJY/r65YfshYkYk3pfWPMU8l7w6NU_C1jfczACLcB/s320/AndroidTemplate.png)

together with the Android panel.

![panel](https://1.bp.blogspot.com/-IaxlNAnLCWw/Vzwgjq4kE5I/AAAAAAAAAJg/UMqmu49mBo0-8Id9Hm4BCsv9bIWQLC9lACLcB/s320/AndroidVS.png)

Also you should have the SDKs downloaded already. If you want to make sure click on the Android SDK Manager icon.

![android sdk manager](https://2.bp.blogspot.com/-t3PM9MLl3Z0/VzwgjkcOouI/AAAAAAAAAJc/6z1zIOQepHw1gm17mHq9sTpuLj0OkgingCLcB/s320/SDKmanager.png)

## 2. Download Xamarin Android Player on OSX

Xamarin Android Emulator on OSX: [https://developer.xamarin.com/guides/android/getting_started/installation/android-player/](https://developer.xamarin.com/guides/android/getting_started/installation/android-player/)

Next get [Xamarin Android Emulator on OSX](https://developer.xamarin.com/guides/android/getting_started/installation/android-player/).
Nothing special, install it and launch it. It will launch the device manager which allows you to download different images with different versions of Android.
Now that we have installed Xamarin on Windows and Xamarin Android Emulator on OSX, we need to establish the connection between both. 

## 3. Establish a connection between your Windows VM and the Xamarin Android Player

Again Xamarin has done a great job in documenting this procedure: [https://developer.xamarin.com/guides/android/deployment,_testing,_and_metrics/debug-on-emulator/xamarin-android-player/#Using_Xamarin_Android_Player_from_Visual_Studio_in_VMWare_or_Parallels](https://developer.xamarin.com/guides/android/deployment,_testing,_and_metrics/debug-on-emulator/xamarin-android-player/#Using_Xamarin_Android_Player_from_Visual_Studio_in_VMWare_or_Parallels)

For me on VMWare, the only step needed is to configure the Network adapter (which is configure this way by default) as __Share with my Mac__

![nat](https://4.bp.blogspot.com/-j8cfBk3n6xw/VzwiqdknLII/AAAAAAAAAJs/qmnACGazLwEE33eOLxuGBa8ogDIDje95gCLcB/s320/configure_networkadapter.png)

After that, get the IP address from the Android player by going to the settings.
Open the Android adb command prompt from Visual Studio toolbar,

![adb](https://4.bp.blogspot.com/-cotgyz-1wOY/VzwkbOZ2-CI/AAAAAAAAAJ4/YEaMvih8cs8AFS0Vnb_to-id61q39EKHQCLcB/s320/adb.png)

and connect Visual Studio to the Android player by typing:
```
adb connect x.x.x.x
```
Wonderful, you should now see your Android player name in the debug dropdown of Visual Studio.

![android player](https://2.bp.blogspot.com/-KV83K2x9ZRM/VzwlPrMuhKI/AAAAAAAAAKA/iHYAG4xUn5MyBHGxoooEjlyshuTKwoZfACLcB/s320/android_pl.png)
![VS](https://2.bp.blogspot.com/-QVSBvl1k0Ts/VzwlQK23v_I/AAAAAAAAAKE/JT8oVJEFAJ4gWY0luVrrvFbWf6_YnuzbwCLcB/s320/debug_vs.png)

You are now ready to start writing an app.

## 4. Start working on your App

Start a C# default Android project and deploy it to the Android player. It should work without any issue.

_I am working with a C# Android project because the F# project template exhibits strange behaviours at the moment. It doesn't allow me to change the target Android version and prompts error on the designer file such as "end is a special keyword"._
_But don't worry, only the Android project is in C#, we will be using F# for Xamarin.Forms._

The Android project will serve as a bootup project from where you can deploy to the device.
To add Xamarin.Forms, create a F# PCL (portable class library) and reference Xamarin.Forms from Nuget.

![project](https://1.bp.blogspot.com/-pdzU-AgGI_g/VzyRIRyuoDI/AAAAAAAAAKg/Mg7AR_vl9jcE6VUATZhrI25q_vPORTeiQCLcB/s320/project.png)

In the F# project, you can now create a Xamarin.Forms app.

Below is an example of what you could put to display a `Hello world!` label.

In the F# project, place the following code:

__App.fs__
```
namespace SimpleApp.Library

open Xamarin.Forms

type App() = 
    inherit Application(MainPage = new ContentPage(Content = new Label(Text = "Hello world!")))
```

And place the following code in the main activity on the C# Android project:

__MainActivity.cs__
```
[Activity(Label = "SimpleApp.Android", MainLauncher = true, Icon = "@drawable/icon")]
public class MainActivity : Xamarin.Forms.Platform.Android.FormsApplicationActivity
{
    protected override void OnCreate(Bundle bundle)
    {
        base.OnCreate(bundle);

        // Initialise Xamarin.Forms
        Xamarin.Forms.Forms.Init(this, bundle);
        
        // Loads the app from the fs library
        LoadApplication(new SimpleApp.Library.App());
    }
}
```

And that's it! If you run the Android project you should get the following:

![app deployed](https://4.bp.blogspot.com/-h818BaT-sj4/VzyTzGO4w0I/AAAAAAAAAKs/BfZR68fjedw0usEg38xlQv60f2Dhr5dTQCLcB/s320/app.png)

The full source code can be found on Github. [https://github.com/Kimserey/SimpleApp](https://github.com/Kimserey/SimpleApp)

__Useful tips:__

1. Add `adb` to path `.bash_profile` in order to have access to `adb shell` quicker
```
export PATH=$PATH:/Users/kimsereylam/Development/android-sdk-macosx/platform-tools
```
2. Use `logcat` to display all the logs while debugging

## Conclusion

Today we saw how we could easily setup an environment to start developing Android apps from Visual Studio on VMware and deploy the app to the Xamarin Android Player.
By showing you that I hope that you will not get discouraged by the initial setup phase and most importantly, I hope that you will get started and code some amazing mobile apps!
If you have any comments, leave it here or hit me on Twitter [https://twitter.com/Kimserey_Lam](https://twitter.com/Kimserey_Lam).
See you next time!  
