# Easily ensure that data is loaded with Ngrx store and router guards in Angular

Last month, I describe [a way to manage global state with ngrx/store](https://kimsereyblog.blogspot.sg/2017/07/managing-global-state-with-ngrx-store.html). With the store, we mamage the overal state of the Angular application in a single global object. Loading and retrieving data affects a single main state object. This simplication gives opportunities to other simplications. Like for example, if we loaded once a collection of items, we wouldn't need to reload it when a component is displayed as it is available in the state. But how can we ensure that and more importantly how can we keep the check logic in a maintainable state. Here enter the Angular router route guard which I also described few weeks ago in my post on [how we could create and manage routes with the Angular router](https://kimsereyblog.blogspot.sg/2017/06/how-to-use-angular-router.html).
Today I will show how we can use both together to solve the issue of ensuring data is loaded before displaying a route.

## 1. Context

Let start back from the previous sample we built in [the previous ngrx store post](https://kimsereyblog.blogspot.sg/2017/07/managing-global-state-with-ngrx-store.html).
You can browse the project before the changes made to demonstrate this blog post 
[here](https://github.com/Kimserey/ngrx-store-sample/tree/f7199b06b2e3277a06a1b4bd6b6ae6523ab794f7).

The sample was having a selection of users which when choosen would load data from a service.

![previous_image](https://raw.githubusercontent.com/Kimserey/ngrx-store-sample/master/example.PNG)

The goal of the post was to demonstrate how ngrx-store works. Therefore in `select-user.ts`, the list of user was hardcoded in the template directly:

```
<select (change)="select($event.target.value)">
    <option value=""> -- Select a user -- </option>
    <option value="joe">Joe</option>
    <option value="kim">Kim</option>
    <option value="mike">Mike</option>
</select>
```

But this previous post left us with the following questions:

1. Where do we load data?
2. How can we ensure that de data is loaded in the page?

## 2. Guard

## 3. Usage

# Conclusion