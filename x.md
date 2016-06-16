# Keep your UI framework up to date for your WebSharper SPA with Paket GitHub dependencies

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

## 2. Use Paket with GitHub dependency to make a file dependency

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
