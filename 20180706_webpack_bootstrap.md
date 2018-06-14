# Compiling Bootstrap with Webpack

Few weeks ago I talked about LibMan which was a tools preinstalled on Visual Studio 2017 preview allowing local download of cdnjs minified css/js. Today I will show how we can configure Webpack with npm to manage libraries like Bootstrap and minify both css and js while applying all its good algorithm like tree shacking.

1. Get started with Webpack
2. Bundle js
3. Bundle css
4. Configure npm

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