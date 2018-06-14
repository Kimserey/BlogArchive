# Compiling Bootstrap with Webpack

Few weeks ago I talked about LibMan which was a tools preinstalled on Visual Studio 2017 preview allowing local download of cdnjs minified css/js. Today I will show how we can configure Webpack with npm to manage libraries like Bootstrap and minify both css and js while applying all its good algorithm like tree shacking.

1. Get started with Webpack
2. Bundle js
3. Bundle css
4. Multiple configurations

## 1. Get started with Webpack

The goal of Webpack is to make it easy for developers to bundle code together and reduce its size in order to provide the smallest functional possible file to serve to users.
In this post, I will show how we can bundle Bootstrap 4.0, both its js and its sass source code in order to provide two bundle, `bundle.js` and `bundle.css`.

Before we look into Webpack, lets look at the steps which would be required to provide the bundles. Bootstrap npm package comes with js modules which are separated by functionality. For example for the `modal`, it is located under `bootstrap/js/dist/modal`. For the `sass` code, it is also available per module and can be compiled with overwrite of variables. The steps to get the bundles will then be for js:

1. Bundle together js module
2. Minify and uglify js
3. Write js to `bundle.js`

And for sass:

1. Compile sass files
2. Apply Postcss for Autofixer
3. Bundle css
4. Minify css
5. Write css to bundle file

## 2. Bundle js

As we saw, the three steps for js are the bundle, the minification and the output.

Before minimizing, we'll start by getting Webpack to work. For that we install it using npm

```sh
npm install webpack webpack-cli --save-dev
```

Once we have webpack installed, we can created the first skeleton of the config file `webpack.config.js`:

```js
const path = require('path');

module.exports = {
    entry: {
        app: './index.js'
    },
    mode: 'development',
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'dist')
    }
};
```

`entry` defines the entrypoint from where Webpack reverse the dependencies and figure what to pack.
`output` defines the file where we will be bundling the js into.
Because we installed Webpack locally, we should have access to the `webpack` command via `npm run`. For that we modify the `package.json`.

```sh
{
  ... some config from package.json
  "scripts": {
    "build": "webpack"
  },
}
```

By default, `webpack` will use `webpack.config.js` else we would need to use `webpack --config myfile.js`. Now we should be able to run `npm run build` and it will bundle the js.
Now for our example, we want to bundle Bootstrap therefore we can install it with:

```sh
npm install bootstrap jquery popper.js --save
```

And we can change our `index.js` to import bootstrap:

```js
import 'bootstrap';
```

Once we `npm run build`, the `bundle.js` will contain the bootstrap code.

So far we have seen how bundling work with Webpack for js files. We seen that it is supported out of the box with `entry` and `output`. Now for minification, we can use the uglify plugin. Plugin in Webpack are functionalities which can be downloaded via npm and registered to the packing process. For example to uglify, we will use `uglifyjs-webpack-plugin`.

```sh
npm install uglifyjs-webpack-plugin --save-dev
```

We then update our config:

```js
const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

module.exports = {
    entry: {
        app: './index.js'
    },
    mode: 'production',
    optimization: {
        minimizer: [
            new UglifyJsPlugin({
                cache: true,
                parallel: true,
                sourceMap: true
            })
        ]
    },
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'dist')
    }
};
```

We import `UglifyJsPlugin` and use it in the `optimization.minimizer` and set the `mode` to `production`. Once we run `npm run build`, we should now end up with a version significantly smaller!
So far we have been minifying the whole Bootstrap code. But what Webpack allows us to do is to only bundle what we need. For example if we need the `modal`, instead of importing the whole bootstrap, we can import only `modal`.

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Test Bootstrap modal</title>
</head>
<body>
    <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#exampleModal">
        Launch demo modal
    </button>
    <div class="modal fade" id="exampleModal" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="exampleModalLabel">Modal title</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    ...
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    <button type="button" class="btn btn-primary">Save changes</button>
                </div>
            </div>
        </div>
    </div>
    <script src="bundle.js"></script>
</body>
</html>
```

Bare in mind that the css has not been applied yet but the `bundle.js` is loaded. The bundle was built by importing the modal module instead of the whole bootstrap library. 

```js
import 'bootstrap/js/dist/modal';
```

Once we rebuild the bundle, we can see that the js crashes with `Uncaught ReferenceError: $ is not defined`. This shows that everything Webpack assumed wasn't used got removed. In this case, jQuery could not be found. In order to make jQuery available, we can use another plugin called the `ProviderPlugin` which provides variables globally.

```js
const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const webpack = require("webpack");

module.exports = {
    entry: {
        app: './index.js'
    },
    mode: 'production',
    plugins: [
            new webpack.ProvidePlugin({
            $: 'jquery',
            jQuery: 'jquery'
        })
    ],
    optimization: {
        minimizer: [
            new UglifyJsPlugin({
                cache: true,
                parallel: true,
                sourceMap: true
            })
        ]
    },
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'dist')
    }
};
```

Now when we rebuild the bundle, the error linked to jQuery is gone but we face another problem `Uncaught ReferenceError: Util is not defined`. To make `Util` available, we need to extract it out of the module using the exports-loader module.

```sh
npm install exports-loader --save-dev
```

And we can then modify the `ProvidePlugin` as followed:

```js
plugins: [
        new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
        Util: 'exports-loader?Util!bootstrap/js/dist/util'
    })
]
```

Now if we rebuild, we should be able to make the js containing only the `modal` work!

## 3. Bundle css

Now that we have seen how to bundle js, we can quickly reproduce the same for css by compiling sass and minifying the resulting css.
Bootstrap comes with all the source sass files, this gives us maximum possibility to change the variables of Bootstrap and recompile the whole project. To demonstrate that, we start first by installing `node-sass`, the package necessary to copile sass.

```sh
npm install node-sass --save-dev
```

Once install we are now ready to install all the necessary modules and plugins for Webpack to bundle our css.

```sh
npm install sass-loader css-loader precss postcss-loader style-loader --save-dev
```

Once we have installed the necessary modules, we can set them up on the config file:

```js
module.exports = {
    entry: {
        app: './index.js'
    },
    mode: 'development',
    module: {
        rules: [{
            test: /\.(scss)$/,
            use: [
                'style-loader',
                'css-loader',
                'postcss-loader',
                'sass-loader'
            ]
        }]
    },
    plugins: [
            new webpack.ProvidePlugin({
            $: 'jquery',
            jQuery: 'jquery',
            Util: 'exports-loader?Util!bootstrap/js/dist/util'
        })
    ],
    optimization: {
        minimizer: [
            new UglifyJsPlugin({
                cache: true,
                parallel: true,
                sourceMap: true
            })
        ]
    },
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'dist')
    }
};
```

Notice the order of the `loaders`, `style-loader` will put the css into the js which will be written directly into the html page.
We also added configurations for `postcss` in the `postcss.config.js`:

```js
module.exports = {
    pulgins: [
        require('precss'),
        require('autoprefixer')
    ]
}
```

Lastly to be able to build the css, we must add an `index.scss` which imports Bootstrap:

```scss
@import "~bootstrap/scss/bootstrap";
```

And in the `index.js` entry point, we must import the scss file.

```js
import './index.scss';
import 'bootstrap/js/dist/modal';
```

This import of scss, although weird, is interpreted by the test `/\.(scss)$/` and go through the different loaders. Next if we build this, we should be able to now see the page styled with Bootstrap and the modal should be working.
But just like the js, if we want to reduce even more the size of the css file, we can opt out of certain module. Therefore instead of importing `~bootstrap/scss/bootstrap` which imports all modules, we can select the modules we are interested in:

```scss
@import "~bootstrap/scss/functions";
@import "~bootstrap/scss/variables";
@import "~bootstrap/scss/mixins";
@import "~bootstrap/scss/root";
@import "~bootstrap/scss/reboot";
@import "~bootstrap/scss/type";
@import "~bootstrap/scss/grid";
@import "~bootstrap/scss/buttons";
@import "~bootstrap/scss/card";
@import "~bootstrap/scss/modal";
@import "~bootstrap/scss/close";
```

This will reduce even further the css produced. Once we have the css built, the next step is to extract it into a separate file, for that we can use `MiniCssExtractPlugin` which can be downloaded from the `mini-css-extract-plugin`:

```sh
npm install mini-css-extract-plugin --save-dev
```

We can then replace the `style-loader` with the `MiniCssExtractPlugin.loader` and provide the filename of the css to the `MiniCssExtractPlugin` plugin:

```js
const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const webpack = require("webpack");

module.exports = {
    entry: {
        app: './index.js'
    },
    mode: 'production',
    module: {
        rules: [{
            test: /\.(scss)$/,
            use: [
                MiniCssExtractPlugin.loader,
                'css-loader',
                'postcss-loader',
                'sass-loader'
            ]
        }]
    },
    plugins: [
        new webpack.ProvidePlugin({
            $: 'jquery',
            jQuery: 'jquery',
            Util: 'exports-loader?Util!bootstrap/js/dist/util'
        }),
        new MiniCssExtractPlugin({
            filename: 'bundle.css'
        })
    ],
    optimization: {
        minimizer: [
            new UglifyJsPlugin({
                cache: true,
                parallel: true,
                sourceMap: true
            }),
            new OptimizeCSSAssetsPlugin({})
        ]
    },
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'dist')
    }
};
```

Once we build webpack, we will now have our `bundle.css` exported to its own file. We now have our two bundles, `bundle.js` and `bundle.css`. We also added an `OptimizeCSSAssetsPlugin` which minifies the css output.

We saw that there was many ways to create the bundle, either we minify or not, or either we export to a file or we directly have it inlined with the js.
When building in development, it is better to prioritize speed over performance while in production, it's better to have the file as small as possible. This differentiation can be implemented by using multiple environment.

## 4. Multiple configurations

In order to support multiple environment like `dev` and `prod`, we will be using `webpack-merge`.

```sh
npm install webpack-merge --save-dev
```

Then we modify our config to name it as `webpack.common.js` containing the common configuration to `dev` and `prod`:

```js
const path = require('path');
const webpack = require("webpack");

module.exports = {
    entry: {
        app: './index.js'
    },
    plugins: [
        new webpack.ProvidePlugin({
            $: 'jquery',
            jQuery: 'jquery',
            Util: 'exports-loader?Util!bootstrap/js/dist/util'
        })
    ],
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'dist')
    }
};
```

Then we can have the `webpack.dev.js`:

```js
const merge = require('webpack-merge');
const common = require('./webpack.common.js');

module.exports = merge(common, {
    mode: 'development',
    devtool: 'inline-source-map',
    module: {
        rules: [{
            test: /\.(scss)$/,
            use: [
                'style-loader',
                'css-loader',
                'postcss-loader',
                'sass-loader'
            ]
        }]
    }
});
```

For development, we use the `style-loader`. Notice that we use `merge` from `webpack-merge` to merge the `common` configuration with the `dev`. Then  we create the `webpack.prod.js`.

```js
const merge = require('webpack-merge');
const common = require('./webpack.common.js');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");

module.exports = merge(common, {
    mode: 'production',
    module: {
        rules: [{
            test: /\.(scss)$/,
            use: [
                MiniCssExtractPlugin.loader,
                'css-loader',
                'postcss-loader',
                'sass-loader'
            ]
        }]
    },
    plugins: [
        new MiniCssExtractPlugin({
            filename: "bundle.css"
        })
    ],
    optimization: {
        minimizer: [
            new UglifyJsPlugin({
                cache: true,
                parallel: true,
                sourceMap: true
            }),
            new OptimizeCSSAssetsPlugin({})
        ]
    },
});
```

Lastly we modify the npm scripts to allow building `dev` and `prod`:

```json
"scripts": {
    "dev": "webpack --config webpack.dev.js",
    "prod": "webpack --config webpack.prod.js"
},
```

We are then able to run `npm run dev` and `npm run prod` for whichever we need to build. That concludes today's post!

## Conclusion

Today we saw how we could use Webpack to bundle js and css files. We saw that Webpack could be used to minify and uglify js but also used to compile sass which provide us a way to overwride the default variables of Bootstrap and recompile the whole scss source code, then rebundle and minify the css output. Lastly we also saw that one of the biggest advantage of Webpack is the ability to select precisely which module is needed in the library used, here we saw how we could bundle only the `modal` module which reduced the whole size of the minified js. Hope you like this post, see you next time!