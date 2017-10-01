# Create extensions for type in typescript

Typescript is a superset of JavaScript. It provides type safety on top of the JS libraries. Type safety is an important part of the development experience as it allows us to detect problems early thanks to the compiler preventing us from writing broken code.
JS being dynamic it is very easy to extend since anything is assumed to exist. In the context of extension methods, the only step needed is to add the method to the prototype of the class and we are done.
Typescript kept that flexibility but in order to provide type safety on top of it, extra steps are needed.

Today I would like to share how we can create extension methods in Typescript by extending existing types. This post will be composed by 2 parts:

```
1. Extending a core type
2. Extending a library type
```

## 1.  Extending a core type

The first thing we need to do is create the function which will become the extension.
Here we will create a sumBy function to extend the Array core type.

```
function sumBy<T>(this: T[], selector: (x: T) => number) {
  return this.reduce((pre, cur) => pre + selector(cur), 0);
}
```

We have a `selector` which will select the property to sum by and we reduce the array by adding all selected properties.

Notice that we use `this` parameter as the first parameter. It is to specify that this function is expected to be called on and instance of an array.

More about `this` on [Typescript documentation].(https://www.typescriptlang.org/docs/handbook/functions.html)

Next we can add the function to the array prototype.

```
Array.prototype.sumBy = sumBy;
```

What we notice here is that Typescript complains that sumBy does not exists. In order to fix this, we need to `declare` the function for `Array`.

```
interface Array<T> {
  sumBy<T>(this: T[], selector: (x: T) => number): number;
}
```

Now we can use it like so:

```
const sum = data.sumBy(x => x.Amount);
```

Make sure to import the module where the extension is defined.

The complete extension code is as followed:

```
interface Array<T> {
  sumBy<T>(this: T[], selector: (x: T) => number): number;
}

function sumBy<T>(this: T[], selector: (x: T) => number) {
  return this.reduce((pre, cur) => pre + selector(cur), 0);
}

Array.prototype.sumBy = sumBy;
```

## 2. Extending a library type

There are times where it is necessary to extend types from external libraries.

For example if we need to extend the Observable type provided by rx/js, we will need to declare the extension in the right module on the original type. Because Observable is inside `rxjs/Observable`, we can `declare` is like so:

```
import { Observable } from 'rxjs/Observable';

declare module 'rxjs/Observable' {
  interface Observable<T> {
    isTrue(this: Observable<T>): Observable<T>;
  }
}

function isTrue<T>(this: Observable<T>) {
  return this.filter(v => !!v);
}

Observable.prototype.isTrue = isTrue;
```

Compared to Array, here we use `declare module 'rxjs/Observable'` in order to add the extension to the right interface.

## Conclusion

Today we saw how to define extension methods for core types and library types for Typescript. It is a convenient way to place reusable and easily accessible code. As usual, if you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!