# How to serve static files with Angular CLI

One of the easiest way to build Angular applicationns is through Angular CLI. Using the `ng serve` command will build and serve the whole application or we can use `ng build` to output the app into the `outputDir` folder, but there might be occasions where we need to serve files which aren't part of the Angular process, like static files or images. Those files are referred to as __assets__. Today we will see how we can configure Angular CLI to copy assets to the output directory and what sort of configuration is available.

```
1. Copying assets
2. Glob file, input, output
```

## 1. Copying assets

Files which need to be served by AngularCLI must be registered under `assets` in the `.angular-cli.json` file.
When we first boostrap a project, there are two places registered under `assets`:

```
{
    "apps": [{
      "root": "src",
      "outDir": "dist",
      "assets": [
        "assets",
        "favicon.ico"
      ]
    }]
}
```

This makes the whole content of `assets` folder and `favicon.ico` file copied to the `outDir`.  If we `ng serve`, we will be able to access favicon under `http://localhost:4200/favicon.ico`. For `assets`, it is a folder, therefore any file under `assets` and any sub folder will be served under `/assets` which we can access under `http://localhost:4200/assets/myfile` or `http://localhost:4200/assets/sub-folder/mysecondfile`.

This is useful if we need to serve some images which we can place under assets. It can also be used to serve static html pages, for example if we need to host an extra file used to handle redirect, `redirect.html` then we can specify the file as asset just like `favicon.ico`. 
__The root of assets is the src folder, set above.__

 This is great already and fits most of the scenarios but AngularCLI allows us to do even more.

## 2. Glob file, input, output

The best way to understand how to configure the AngularCLI is to have a look at its json schema located under `./node_modules/@angular/cli/lib/config/schema.json`.

We can see the `assets` section:

```
"assets": {
  "type": "array",
  "description": "List of application assets.",
  "items": {
    "oneOf": [
      {
        "type": "string"
      },
      {
        "type": "object",
        "properties": {
          "glob": {
            "type": "string",
            "default": "",
            "description": "The pattern to match."
          },
          "input": {
            "type": "string",
            "default": "",
            "description": "The dir to search within."
          },
          "output": {
            "type": "string",
            "default": "",
            "description": "The output path (relative to the outDir)."
          }
        },
        "additionalProperties": false
      }
    ]
  },
  "default": []
}
```

The interesting part is the `items`, which is `oneOf` a `string` __or__ and `object`.
The `string` is what we discussed in 1), which is placing folder and files to be served directly from root.
The `object` is more interesting, as we can see that it has 3 properties:

- glob representing a pattern to match against files,
- input representing the directory where the glob pattern will be applied,
- output representing the directory where the file will be copied.

For example, we could have download a library via npm, for example `my-lib` which we wish to:
1. keep in node_modules
2. serve on the root so that from our static files we can do `<script src="my-lib/my-lib.js"></script>`

In order to do that we can configure the asset as followed:

```
{
    "glob": "*.js",
    "input": "../node_modules/my-lib/",
    "output": "./my-lib"
}
```

Specifying the glob pattern will allow to filter only js files and copied it back to a folder specific to the `my-lib`.

# Conclusion

Today we saw how to configure assets to be copied over to the output directory. We saw two different ways supported by AngularCLI, one via direct name of file or directory and the second one by specifying a glob pattern. This is particularly useful for copying libraries which we don't want to mix with Angular bundle. It is also useful for images or static files in general. Hope this was useful, if you have any questions, leave it here or hit me on Twitter [@https://twitter.com/Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you later!