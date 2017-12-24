# Publish Angular application with Angular CLI and AspDotNet Core

A few month back I showed how to bootstrap an Angular application using Angular CLI. Apart from bootstrapping and serving, Angular CLI is also capable of packing the application and get it ready to be published. 
We can then use the published site and serve it on our own webserver. Today we will see how the process of publishing can be done in three steps

```
1. Prepare the project for packing
2. Create a host
3. Publish the application
```

## 1. Prepare the project for packing

In order to ease the understanding, we start by separating our client Angular application and Host application.

The client will go into `/client` while the host into `/host`.

Now that we have proper folder separation we can build using `ng build`. To set the output folder we can modify the value in Angular CLI configuration.

For now we can leave it as is. 

## 2. Create the host

Under the host folder, we can create an empty AspDotNet Core application. This will be our webserver hosting our Angular application.

Because the files packed our all static files, html, css, js etc.. we need to add the

Create application under client

Create host aspnet core under host

Use ServeFile in aspnet core. The default behaviour is that AspNetCore will look into the wwwroot folder for an index.html page to serve which is ideal for our scenario. Once ready we can create a simple helloworld index.html and navigate to our host.

```
```

## 3. Publish the application

First thing we need to do is to setup Ng CLI to write the package webapp to the wwwroot folder of our host.
This can be done by modifying the outDir in the angular-cli.json to output to wwwroot.

```
```

Now that we have that we can `ng build`, it will compile pack and copy to the wwwroot. Then we can `dotnet publish` on the host which will pack every library together with the wwwroot is the publish folder. And that's it we have our artefact ready.

To run it, navigate to the folder and do `dotnet host.dll`.

# Conclusion

Today we saw how we could publish and host an Angular application using Angular CLI functionalities together with an AspNetCore host application. The steps can quickly be implemented and automated for continuous delivery. Hope you liked this post as much as I like writting it. Sse you next time!