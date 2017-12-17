# Publish Angular application with Angular CLI and AspDotNet Core

A few month back I showed how to bootstrap an Angular application using Angular CLI. Apart from bootstrapping and serving, Angular CLI is also capable of packing the application and get it ready to be published. Once packed, we still need to create our webserver which will be capable of serving our Angular application. Today we will see how the process of publishing can be done in three steps

1. Prepare the project for packing
2. Create a host
3. Publish the application

1. Prepare the project for packing

In order to ease the understanding, we start by separating our client Angular application and Host application.

The client will go into `/client` while the host into `/host`.

Now that we have proper folder separation we can build using `ng build`. To set the output folder we can modify the value in Angular CLI configuration.

For now we can leave it as is. 

2. Create the host

Under the host folder, we can create an empty AspDotNet Core application. This will be our webserver hosting our Angular application.

Because the files packed our all static files, html, css, js etc.. we need to add the

Create application under client

Create host aspnet core under host

Modify outDir in cli config to output to wwwroot

Use ServeFile in aspnet core

Ng build
Ng publish -o dist