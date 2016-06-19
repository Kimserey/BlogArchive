# Keep your UI framework up to date for your WebSharper SPA with Paket GitHub dependencies

Have you ever been guilty of referencing `Bootstrap` in your web app __just__ to use one feature (like the navbar for example)?

Hunting for the most full featured CSS/JS UI framework for hours.
Referencing a huge framework just to use one or two features.
`Bootstrap`, `Foundation`, `MUI` or `Materialize`, there are so many that it takes a lot of time to find the one that fits your needs.

Few months back, I started to build a prototype to manage expenses and all I needed was a `navbar` and a `card` style.
Because of bad habits, I directly started to hunt for a UI framework which would provide me beautiful cards.
After few hours of search, I realised how time consuming that was and most importantly how unlikely would it be for me to find something tailored for my needs.
So I decided to do something that I should have done long ago - __Build my own tailored JS/CSS UI framework__.

So today, I will share what I've learnt during the process of creating the JS/CSS UI framework. This post is composed by two parts:
    
    1. Build your UI framework with JS and SCSS
    2. Use Paket with GitHub dependency to keep your web app on the latest update of your UI framework

## 1. Build your UI framework with JS and SCSS

To write this UI framework, I used JS and SCSS (SASS).
I won't talk about the JS part as I used it purely to handle on click events and show/hide certain elements.
I chose SCSS because it has a more natural way of defining CSS classes than directly writing in CSS.

The main benefits that SCSS or SASS bring me are the following:
 
1. Variables
2. Nested style
3. Imports
4. Mixins

### 1.1 Variables

You can declare variables. 
These variables can then be used anywhere and assigned to any style.

```
$grey: #808080;

...somewhere else...

color: $grey;
border-bottom: 1px solid $grey;
```
Here's an example usage: [https://github.com/Kimserey/SimpleUI/blob/master/scss/shared/_colors.scss](https://github.com/Kimserey/SimpleUI/blob/master/scss/shared/_colors.scss)

### 1.2 Nested style - Ampersand (&)

The creation of nested style is made more intuitive.
The hiearchy of your classes is respected by the hierarchy defined defined by the HTML elements.

```
.card {
    .card-list {
        ...
    }
}
```

This will match the following HTML:
```
<div class="card">
    <div class="card-list"></div>
</div>
```

`&` can be used within a class to reference to the parent. It is a clean way to define child classes.

```
.card {
    &.active {
        ...
    }
}
```

This will match the following HTML:
```
<div class="card">
    <div class="card-list active"></div>
</div>
```

### 1.3 Imports

You can separate your style into multiple file.
`@import` lets you import partial files prefixed with an underscore `_`. 

```
@import "components/amount";
@import "components/card";
@import "components/mask";
@import "components/nav";
@import "components/table";
```
Here's an example usage: [https://github.com/Kimserey/SimpleUI/blob/master/scss/SimpleUI.scss](https://github.com/Kimserey/SimpleUI/blob/master/scss/SimpleUI.scss)

### 1.4 Mixins

You can create reusable functions which sets some styles using `@mixins` and `@include` to include them in your classes.

```
@mixin transition($args...) {
  -webkit-transition: $args;
  -moz-transition: $args;
  -ms-transition: $args;
  -o-transition: $args;
  transition: $args;
}

...somewhere else...

@include transition(0.2s);
```

Here's an example usage: [https://github.com/Kimserey/SimpleUI/blob/master/scss/mixins/_transition.scss](https://github.com/Kimserey/SimpleUI/blob/master/scss/mixins/_transition.scss)

### 1.5 Configure Visual Code with Gulp

SCSS needs to be translated to CSS.
For that we can use `gulp` to create a task which will build the CSS then minify it and then minify our JS together in one operation.

First install `gulp` from `npm` by executing the following commands:

```
npm install --save-dev gulp
npm install --save-dev gulp-sass
npm install --save-dev gulp-minify-css
npm install --save-dev gulp-uglify
```

Then create a `gulpfile.js` file in the root folder:

```
var gulp = require('gulp');
var sass = require('gulp-sass');
var minifyCss = require('gulp-minify-css');
var uglify = require('gulp-uglify');

gulp.task('default', function() {
    gulp.src('./scss/SimpleUI.scss')
        .pipe(sass())
        .pipe(gulp.dest("./css"));

    gulp.src('./css/SimpleUI.css')
        .pipe(minifyCss())
        .pipe(gulp.dest('./dist/css'));

    gulp.src('./js/SimpleUI.js')
        .pipe(uglify())
        .pipe(gulp.dest('./dist/js'))
});
```

This task instructs `gulp` to take our main SCSS `SimpleUI.scss` and compile the CSS using the `sass` function.
Then outputs the result in the `/css` folder.
Then take the `SimpleUI.css` results and minifies it using the `minifyCss` function and place the result in the `dist` folder (short form for distribution).
Then does the same for `SimpleUI.js`.

Lastly what we need to do is create a `.vscode` folder, create a `tasks.json` file and add the following:

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

Now `CTRL` + `SHIFT` + `B` should launch the task and build the minified CSS and JS.

_Also the task should be accessible from `CTRL` + `SHIFT` + `P`, Run Tasks_.

The full `SimpleUI` source code can be found here: [https://github.com/Kimserey/SimpleUI](https://github.com/Kimserey/SimpleUI)

Congratulation, you can now start to build your own JS/CSS framework!

## 2. Use Paket with GitHub dependency to keep your web app on the latest update of your UI framework

Last week I talked about how WebSharper manages resources for SPA [https://kimsereyblog.blogspot.co.uk/2016/06/three-ways-to-manage-your-resources-for.html](https://kimsereyblog.blogspot.co.uk/2016/06/three-ways-to-manage-your-resources-for.html).
I mentioned that the JS and CSS can be bundled together with the web app JS - __but in order to do that, you need to place your resources as embedded resources.__

__So how do I embed the JS and CSS created ealier into my web app?__

The best way I found was to:

    1. Push your code into a GitHub repository
    2. Use Paket GitHub dependency to add a dependency on your UI framework
    3. Embed the paket files into your WebSharper project

After you have pushed your git repo like mine [https://github.com/Kimserey/SimpleUI](https://github.com/Kimserey/SimpleUI),
you can use Paket to add a dependency on a GitHub file.

_If you haven't heard of Paket before, I made a small tutorial on how to get started with Paket [https://kimsereyblog.blogspot.co.uk/2016/01/quick-setup-with-paket-and-fsx-scripts.html](https://kimsereyblog.blogspot.co.uk/2016/01/quick-setup-with-paket-and-fsx-scripts.html)._

To add a Paket GitHub file dependency, go to `paket.dependencies` under your root folder and add the following lines:

```
github Kimserey/SimpleUI dist/css/SimpleUI.css
github Kimserey/SimpleUI dist/js/SimpleUI.js
```

Here's an example: [https://github.com/Kimserey/SimpleUIWeb/blob/master/paket.dependencies#L9](https://github.com/Kimserey/SimpleUIWeb/blob/master/paket.dependencies#L9)

Then run the following command in your terminal:

```
.paket\paket.exe update
```

Excellent, you should now have your files added under a `paket-files` folder and you can then add the two files as `Embedded resource` in your WebSharper SPA project.
Finally, add the resources with the `BaseResource` attribute and the `Require` attribute like followed: 
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

_Tutorial on how to manage resources with `BaseResource` and `Require attribute` can be found here: [https://kimsereyblog.blogspot.co.uk/2016/06/three-ways-to-manage-your-resources-for.html](https://kimsereyblog.blogspot.co.uk/2016/06/three-ways-to-manage-your-resources-for.html)_

The full code source can be found here: [https://github.com/Kimserey/SimpleUIWeb](https://github.com/Kimserey/SimpleUIWeb)

That's it, we are done.
No more excuses to not build your own UI framework!
Now your project will always remain up to date with your latest release of your UI framework!

# Conclusion

If you are building something for yourself, come out with your own rules.
Build your own layout, build your own components and even if it sucks at the beginning, as you persist, you will get a better sense of what has to be done.
So if you only need few components, don't waste your time trying to find a gigantic framework, just write your own.
I promise you that in few hours you will have a complete UI framework tailored for your needs.
Combine that with the ease of creating SPA with WebSharper and Paket to always stay in sync with your latest release and you have a very good candidate for the best setup of the year to build SPA.
Hope you enjoyed reading this post as much as I enjoyed writing it. If you have any comment, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).
See you next time!
