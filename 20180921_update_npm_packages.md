# Update NPM packages for frontend projects with npm-check-updates

Frontend libraries progress very rapidly. After just one month, a project can see all its packages needing an upgrade. Today how we can achieve that in ways:

1. `install` vs `update`
2. Using `npm-check-updates`

## 1. Install vs Update

### 1.1 `npm install`

`npm install` will install packages which are found in `package.json` but aren't downloaded. 

For example, we have a project where we installed `Primeng 6.0.0` with `npm install --save primeng@6.0.0`. The sementic versioning rule placed in `package.json` is as followed:

```json
"dependencies": {
    ... some packages,
    "primeng": "^6.0.0"
}
```

The `^` (caret) specifies that minor or patches upgrades are allowed for packages above 1.0.0. For 0.x.x changes, minor changes are considered major therefore only patches upgrades are allowed. Official documentation of the versioning can be found on npm site [https://docs.npmjs.com/misc/semver](https://docs.npmjs.com/misc/semver).

If we run `npm ls primeng`, we will see that `6.0.0` is installed:

```cmd
$ npm ls primeng
my-app@0.0.0 C:\Projects\my-app
`-- primeng@6.0.0
```

Now `primeng@6.0.2` is out, and following the sementic, our project should be able to support it without breaking change. But running `npm install` will only try to install packages that aren't installed yet therefore will skip `primeng`. What we need to do is to run `npm update`.

__View latest available version__

We can know that a newer version is available by hovering over the `package.json` dependency line in Visual studio code or we can run the following command:

```cmd
$ npm view primeng version
6.0.2
```

`npm view primeng` would show the data of the package and `version` allows to show a single property of it.

### 1.2 `npm update`

`npm update` will download the latest version of the package while honoring the versioning specified in `package.json`. 

```cmd
$ npm update               
+ primeng@6.0.2             
updated 1 package in 7.724s 

$ npm ls primeng
my-app@0.0.0 C:\Projects\my-app
`-- primeng@6.0.2
```

As we can see now we have installed `6.0.2`. And if we look at our `package.json` we will see that it has changed to `^6.0.2`.

Now lets step back and downgrade to `5.0.0` by modifying `package.json` to `^5.0.0` and running `npm install`.

```cmd
$ npm ls primeng
primeng-overlay-issue@0.0.0 C:\Projects\primeng-overlay-issue
`-- primeng@5.2.7

$ npm view primeng versions                                     
[ '0.1.0',                         
  '0.2.0',                         
  ...,
  '5.2.5',
  '5.2.6',
  '5.2.7',
  '6.0.0-alpha.1',
  '6.0.0-alpha.2',
  '6.0.0-beta.1',
  '6.0.0-rc.1',
  '6.0.0',
  '6.0.1',
  '6.0.2' ]
```

We can see that `5.2.7` was installed which make sense since `5.2.7` is the latest allowed for `^5.0.0`. Now in this case, we wouldn't be able to bump the major, therefore we would have to install the new version of `primeng` by running:

```cmd
npm install --save primeng@6.0.2
```

And we would be back to the latest version with the proper sementic rule in `package.json`. But the problem with that is that we had to know that a newer version was released. And if we have multiple packages, it can be difficult. For that we can use `npm-check-updates`.

## 2. Using `npm-check-updates`