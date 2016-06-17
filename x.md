# Keep your UI framework up to date for your WebSharper SPA with Paket GitHub dependencies

Have you ever been guilty of referencing `Bootstrap` in your web app __just__ to use one feature (like the navbar for example)?
I am.

Hunting for the most full featured CSS/JS UI framework for hours.
Referencing a huge framework just to use one or two features.
`Bootstrap`, `Foundation`, `MUI` or `Materialize`, there are so many that it takes a lot of time to find the one that fits your needs.

So few months back, I started to build a prototype to manage expenses and all I needed was a `navbar` and a `card` style.
Because of bad habits, I directly started by hunting for a UI framework which would provide me beautiful cards.
After few hours of search, I realised how time consuming that was and most importantly it would be very unlikely that I find something tailored for me.
So I decided to do something that I should have done long ago - __Build my own tailored CSS/JS UI framework__.

So today, I will share the whole process of creating the UI framework. This post is composed by two parts:
    
    1. Build your UI framework with JS and SCSS
    2. Use Paket with GitHub dependency to keep your web app on the latest update of your UI framework

## 1. Start with SCSS

An introduction to SCSS

Configure VS with Gulp.

```
npm install --save-dev gulp
npm install --save-dev gulp-sass
npm install --save-dev gulp-minify-css
npm install --save-dev gulp-uglify
```

```
var gulp = require('gulp');
var sass = require('gulp-sass');
var minifyCs = require('gulp-minify-css');
var uglify = require('gulp-uglify');

gulp.task('default', function() {
    gulp.src('./scss/SimpleUI.scss')
        .pipe(sass())
        .pipe(gulp.dest("./css"));

    gulp.src('./css/SimpleUI.css')
        .pipe(sass())
        .pipe(gulp.dest('./dist/css'));

    gulp.src('./js/SimpleUI.js')
        .pipe(uglify())
        .pipe(gulp.dest('./dist/js'))
});
```

In `\.vscode\tasks.json`

```
{
    "version": "0.1.0",
    "command": "gulp",
    "isShellCommand": true,
    "tasks": [
        {
            "taskName": "default",
            "isBuildCommand": true,
            "showOutput": "always",
            "isWatching": true
        }
    ]
}
```

[https://github.com/Kimserey/SimpleUI](https://github.com/Kimserey/SimpleUI)

## 2. Use Paket with GitHub dependency to keep your web app on the latest update of your UI framework

Some instruction to get running with Paket can be found here:
[https://kimsereyblog.blogspot.co.uk/2016/01/quick-setup-with-paket-and-fsx-scripts.html](https://kimsereyblog.blogspot.co.uk/2016/01/quick-setup-with-paket-and-fsx-scripts.html)

In paket.dependencies add:

```
github Kimserey/SimpleUI dist/css/SimpleUI.css
github Kimserey/SimpleUI dist/js/SimpleUI.js
```

Then run 
```
.paket\paket.exe update
```

Add the 2 files as `Embedded resource`.

Boot a WebSharper SPA and add the following:

```
namespace SimpleUIWeb

open WebSharper
open WebSharper.Resources
open WebSharper.JavaScript

module Resources =
    
    type Fontawesome() =
        inherit BaseResource("https://use.fontawesome.com/269e7d57ca.js")

    type Css() =
        inherit BaseResource("SimpleUI.css")
    type Js() =
        inherit BaseResource("SimpleUI.js")

    [<assembly:Require(typeof<Fontawesome>);
      assembly:Require(typeof<Css>);
      assembly:Require(typeof<Js>)>]
    do()

[<JavaScript>]
module Client =
    open WebSharper.UI.Next
    open WebSharper.UI.Next.Html
    open WebSharper.UI.Next.Client
    
    let Main =
        Console.Log "Started"
```

Tutorial on how to manage resources with `BaseResource` and `Require attribute` can be found here:
[https://kimsereyblog.blogspot.co.uk/2016/06/three-ways-to-manage-your-resources-for.html](https://kimsereyblog.blogspot.co.uk/2016/06/three-ways-to-manage-your-resources-for.html)

The full code source can be found here:
[https://github.com/Kimserey/SimpleUIWeb](https://github.com/Kimserey/SimpleUIWeb)

# Conclusion

If you are building something for yourself, come out with your own rules.
Build your own layout, build your own components and even if it sucks at the beginning, as you persist, you will get a better sense of what has to be done.
So if you only need few components, don't waste your time trying to find a gigantic framework, launch your editor and write your own.
I promise you that in few hours you will have a complete UI framework tailored for your needs.
Hope you enjoyed reading this post as much as I enjoyed writing it. If you have any comment, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).
See you next time!
