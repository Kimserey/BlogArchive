# Progressive Web App with Angular

Progressive Web App allows an Angular website to be installed locally and be available on the app drawer and on the home screen of a phone. Today we will see how to use Angular Progressive Web App module to transform our app into a mobile app. This post is composed by two parts:

1. Install @angular/pwa
2. Configure service worker

## 1. Install @angular/pwa

To install the progressive web app package we use `ng` CLI in the root of the project:

```
ng add @angular/pwa
```

`pwa` stands for progressive web app. It will install `@angular/pwa` and `@angular/service-worker`. 
The progressive web app comes with a default `manifest.json` created at the `src` of the project which defines the icon, the color theme and boundries of the app in regards to the website. For example this is a `manifest.json` generated for `My App`:

```
{
  "name": "My App",
  "short_name": "My App",
  "theme_color": "#1976d2",
  "background_color": "#fafafa",
  "display": "standalone",
  "scope": "/",
  "start_url": "/",
  "icons": [
    {
      "src": "assets/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-96x96.png",
      "sizes": "96x96",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-128x128.png",
      "sizes": "128x128",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-144x144.png",
      "sizes": "144x144",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-152x152.png",
      "sizes": "152x152",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-384x384.png",
      "sizes": "384x384",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

We can see that it defines the following properties:
 - the `name`, `short_name` and `icons` defines the look on the app drawer, the splashscreen and the popup to add to home screen for the app,
 - the `theme_color` defines the color used to tint the UI elements on mobile, it will define the tint of the address bar and the notification bar. `theme_color` defined in `index.html` will overwrite the one defined in `manifest.json`,
 - the `scope` defines the url scope of the progressive web app and where it should break back out to browser, here our whole website is meant to act as an app therefore the scope is the root `/`,
 - the `start_url` defines the path where the app should start on when launched,
 - the `display` defines how the browser UI displays the app - here `standalone` indicates that it should look and feel like a native app,
 - the `background_color` defines the background color used on the splashscreen.

[The full documentation can be found on Google documentation.](https://developers.google.com/web/fundamentals/web-app-manifest/)

It should also be automatically added to the assests in `angular.json` under `build` and `test` architects.

To make sure that our manifest is found, we can run the application and look into the chrome debugger > Application section, we should be able to see our settings:

![manifest]()

## 2. Configure service worker

As we saw in 1), installing `@angular/pwa` with `ng` CLI also installed `@angular/service-worker`. A service worker brings offline capabilities to a web application. It can be viewed as a caching layer for HTTP methods. `@angular/service-worker` provides an abstraction over service worker which would normally be coded in Javascript. It allows us to configure the caching mechanism via a Json file called `ngsw-config.json` which can be found at the root of the project. Installing the package also registered the `ServiceWorkerModule` in the `AppModule`:

```
@NgModule({
  declarations: [AppComponent],
  imports: [
    ...
    ServiceWorkerModule.register('ngsw-worker.js', { enabled: environment.production })
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
```

```
{
  "index": "/index.html",
  "assetGroups": [
    {
      "name": "app",
      "installMode": "prefetch",
      "resources": {
        "files": [
          "/favicon.ico",
          "/index.html",
          "/*.css",
          "/*.js"
        ]
      }
    }, {
      "name": "assets",
      "installMode": "lazy",
      "updateMode": "prefetch",
      "resources": {
        "files": [
          "/assets/**"
        ]
      }
    }
  ]
}

```