# Setup vscode to work with sass effortlessly

Writing sass is very easy with code. Today we will see how we can leverage some NPM packages to compile SASS to CSS, watch file changes and live update the browser for an effortless style development. This post will be composed by 3 parts:

```
 1. Setup vscode task
 2. Create a Gulp build script
 3. Use live-server for live reload
```

![img])(https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20170323_setup_vscode_sass/live-reload.gif)

__The tasks are from the example of vscode documentation to compile sass [https://code.visualstudio.com/docs/languages/css#_transpiling-sass-and-less-into-css](https://code.visualstudio.com/docs/languages/css#_transpiling-sass-and-less-into-css).__

## 1. Setup vscode task

To use code tasks, we need to create a `tasks.json` file under the hidden `/.vscode` folder.

```
| - .vscode
    - tasks.json
| - style.scss
| - index.html

```

The tasks allow us to execute programs by selecting from the search bar `CMD + shift + P`, `Run build task`. If a default task is set, it can directly be triggered by `CMD + shift + B`.

As a first example we can start by installing the sass compiler with `node-sass`.

```
npm install -g node-sass less
```

And create a task which runs `node-sass`:

```
{
    "version": "0.1.0",
    "command": "node-sass",
    "isShellCommand": true,
    "args": ["styles.scss", "styles.css"]
}
```

If we press `CMD + shift + B`, it will compile the `style.scss` and produce `style.css`.
Now that we know how the task manager works, lets see how we can use `Gulp` to do the compilation.

## 2. Create a Gulp build script

We start first by installing `gulp` and the `gulp-sass`.

```
npm install -g gulp
npm install gulp-sass
```

Now that we have `gulp` installed, we can create a build script `gulpfile.js` which we place in the root.

```
var gulp = require('gulp');
var sass = require('gulp-sass');

gulp.task('sass', function() {
    gulp.src('scss/*.scss')
        .pipe(sass())
        .pipe(gulp.dest('.'));
});

gulp.task('default', ['sass'], function() {
    gulp.watch('scss/*.scss', ['sass']);
})
```

Here we import `gulp` and `gulp-sass` and create a task called `sass` and use the `sass()` function to compile the CSS and output it into the root folder destination `/.`.
Then we set a tasj watcher named `default` where we specify that a dependent task `sass` needs to be run before `default` can be. Within the task, we set the watcher to execute `sass` task when files are changed within the files which match the following pattern: `scss/*.scss`.

Once we done that we can modify the `tasks.json` to execute `gulp` directly and pass the `default` task as arguemnt:

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
            "isBackground": true
        }
    ]
}
```

By default the name of the task is given as arguemnt, the task above will execute the following: 

`gulp default`

This works because `default` is the name of our `gulp` task. If we need to have another name, we can use `suppressTaskName` and pass an argument `default`:

```
{
    "version": "0.1.0",
    "command": "gulp",
    "isShellCommand": true,
    "echoCommand": true,
    "tasks": [{
        "taskName": "sass-1",
        "suppressTaskName": true,
        "args": [
            "default"
        ],
        "isBuildCommand": true,
        "showOutput": "always",
        "isBackground": true
    }]
}
```

This will have the same effect.
Now that we have a build script which can be started with `CMD + shift + B`, which compile CSS and watch for SCSS file changes, we can use a live reload to automatically propagate changes.

##  3. Use live-server for live reload

In order to achieve live reload, we will be using `live-server` which is a convenient tool to have while developing. `live-server` hosts the root folder in a default endpoint and injects live reload capabilities to the pages served.

First we install it globally with npm:

```
npm install -g live-server
```

After install from anywhere, we should be able to use `live-server` from the command line to start a server on the current folder.

Since we are using `gulp`, we can add the `live-server` command to our previous script:

```
var gulp = require('gulp');
var sass = require('gulp-sass');
var exec = require('child_process').exec;

gulp.task('sass', function() {
    gulp.src('scss/*.scss')
        .pipe(sass())
        .pipe(gulp.dest('.'));
});

gulp.task('watch', ['sass'], function() {
    gulp.watch('scss/*.scss', ['sass']);
})

gulp.task('default', ['watch'], function() {
    exec("live-server");
});
```

And we are done! Now every time the scss files are updated, the css is recompiled and every time any file is updated, the server reloads the browser!

![img])(https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20170323_setup_vscode_sass/live-reload.gif)

# Conclusion

Today we saw how we could setup `gulp` to compile SCSS and use `live-server` to host and live reload our website. It is very easy to use gulp to create build script and produce one-click scripted (semi-automation) and vscode tasks integration makes it even easier. Hope you liked this post, if you have any comments, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Other posts you will like

- How to make a sticky navbar using Bootstrap v4 -[https://kimsereyblog.blogspot.sg/2017/03/how-to-make-sticky-navbar-using.html](https://kimsereyblog.blogspot.sg/2017/03/how-to-make-sticky-navbar-using.html)
- Post form data to webserver from HTML or JS - [https://kimsereyblog.blogspot.sg/2017/02/post-form-data-to-server.html](https://kimsereyblog.blogspot.sg/2017/02/post-form-data-to-server.html)
- Get your own domain name and setup SSL with Cloudfare - [https://kimsereyblog.blogspot.sg/2016/08/get-your-domain-name-and-setup-ssl-with.html](https://kimsereyblog.blogspot.sg/2016/08/get-your-domain-name-and-setup-ssl-with.html)
