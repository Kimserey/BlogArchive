Have you ever wondered what needs to be done to push an app on google play store?
How many steps are involved? How much does it cost? What information is needed?
Few weeks ago I asked myself those questions. To answer those, I decided to publish an app on Google play store.
Last week I completed a simple application and pushed it under alpha release on the Play store so today I would like to share what I did so that you will know how to do it too.

This post is composed by three parts

Build the aligned apk
Activate the google play developer console 
Push your app

My development stack is VS2015 Xamarin forms and Xamarin Android.

Once you completed your app the first thing to do would be to generate a keystore.
We will need the keystore to signed the apk.

The command to use the keystore is

Keygen -keystore name ....

This will create a keystore file.
Then click on Tools > Android > Publish 
And use the keystore, put the password you set while creating the keystore and the name used.

This process will create an aligned apk. The aligned apk is the one that we will upload to the store.

2. Google account

Now head to the Google play developer store and complete the process to open an account. 
Here you will need to pay 25 dollars to activate your account.
Once you have the account you can load the APK.

3. Push your app

After your apk is loaded before being able to push the app, some documents need to be provided and some information need to be completed.
You need to provide a high resolution icon 512x512 (the icon which will be displayed in the store) and a feature graphic (the image which will appear at the top of the store).
You also need to provide a description and a tag line and complete some other details like agreeing ....

Once you've done that you should be able to click publish.

The app does not get published instantly, so just wait a few hours and that's it! Congratulation you have deployed an app on Google play store!

Conclusion

Today we saw how we could take a completed application and publish it to Google play store. I hope you could get a sense of what has to be done to publish. The process isn't difficult and it takes just few minutes to complete if you already have an icon and a banner for yout page in the store.
Hope you enjoyed reading this post as much as I enjoyed writing it, as always if you have any question leaveit here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!
