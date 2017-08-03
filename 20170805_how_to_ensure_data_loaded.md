# Easily ensure that data is loaded with Ngrx store and router guards in Angular

Last month, I describe [a way to manage global state with ngrx/store](https://kimsereyblog.blogspot.sg/2017/07/managing-global-state-with-ngrx-store.html). With the store, we mamage the overal state of the Angular application in a single global object. Loading and retrieving data affects a single main state object. This simplication gives opportunities to other simplications. Like for example, if we loaded once a collection of items, we wouldn't need to reload it when a component is displayed as it is available in the state. But how can we ensure that and more importantly how can we keep the check logic in a maintainable state. Here enter the Angular router route guard which I also described few weeks ago in my post on [how we could create and manage routes with the Angular router](https://kimsereyblog.blogspot.sg/2017/06/how-to-use-angular-router.html).
Today I will show how we can use both together to solve the issue of ensuring data is loaded before displaying a route.

## 1. Context

## 2. Guard

## 3. Usage

# Conclusion