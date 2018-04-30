# Async pipe versus Subscribe in Angular

Over the past year, working in companies using Angular, many times have I been in situations where I was asked to explain the differences between `async` pipe and `.subscribe` in Angular. 
More precisely explain my standpoint which is to __always use async pipe when possible__ and __only use `.subscribe` when side effect is an absolute necessity__.
The challenge in explaining this comes to how to convince without giving an hour boring lesson of why side effects in logic are hard to maintain and how prematured `.subscribe` forces developers to make unecessary side effects.
So today I would like to cover that subject and provide an explanation which I hope will answer the question of when to use which. This post will be composed of three parts:

1. Observable and Rxjs
2. Subscribe function
3. Async pipe

## 1. Observable ans RxJS

First to understand the context, we need to understand what is an observable.

### 1.1 Observable

Observable is an abstraction of asynchronous stream of data.

For example, when we look at `Observable<string>`, it represents a stream of strings. This means that the class represents a stream of strings which will be delivered one by one over the time.

__Now why would we care?__

We need to care because stream of data coming in an asynchronous fashion is __extremely__ hard to think about. Even worse when multiple streams need to be combined. Thinking about time is very error prone.

So far we know that Observable is an abstraction of asynchronousy and that it is very hard to work with stream of data. So how do we combine streams of data? Here comes RxJS operators.

### 1.2 RxJS

RxJS operators, which can be found under `add/operator`, allow us to operate directly on observables, modifying , combining, aggregating, filtering data of observables.

[http://reactivex.io/documentation/operators.html](http://reactivex.io/documentation/operators.html)

I have said this to many people and this is the most valuable piece of advise I have:

__You are safe as long as you stay in the Observable.__

We must to keep the observable, combining it or modifying it using RxJS operators. As long as we stay within the observable, we do not need to think about the bigger picture. All we need to think about is what to do with the single string we receive. We don't need to care about the fact that we will receive multiple values over the time hence the safety. The power of RxJS is that each operation is assured to be receiving as input the output of the previous operation. This is an extremely powerful model which allows developers to easily follow the logic and makes the code predictable.

But if we keep the Observable modifying it around, how do we display data?

This is where we have been used to `.subscribe`.

## 2. Subscribe function

We pass the observable around, combining it saving it to different variables with different combination of operators but at the end, an `Observable<T>` is useless on its own. We need a way to "terminate" the observale and extract the type `T` out of it.
That is what subscribe is used for. To subscribe to the resulting stream and terminate the observable.

Now many times I have seen the following:

```ts
name: string;

onInit() {
this.getName()
   .subscribe(name => {
       this.name = name;
   });
}
```

In order to keep the observable, we would transform it as such:

```ts
name$: Observable<string>;

onInit() {
this.name$ = this.getName();
}
```

The dollar `$` is a convention to know that the variable is an observable. Then to display from the UI, we would need to use the async pipe.

```ts
{{ name$ | async }}
```

## 3. Async.pipe
