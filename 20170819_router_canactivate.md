# Difference between CanActivate and CanActivateChild in Angular Router

Few weeks ago I spoke about the functionality of the Angular Router [http://kimsereyblog.blogspot.com/2017/05/attribute-route-in-asp-net-core.html](http://kimsereyblog.blogspot.com/2017/05/attribute-route-in-asp-net-core.html). It was a brief overview of all the router features but one of the feature was not totally explain, the `CanActivate` feature. From there a question emerged, __what is the difference between CanActivate and CanActivateChild?__. Today I will answer this question and at the same time discussing extra behaviours of the router with this post composed by 4 parts:

```
1. Refresh on CanActivate and CanActivateChild
2. Difference
3. Some considerations
4. Component reusability with router
```

## 1. Refresh on CanActivate and CanActivateChild

As we saw in my previous post, `CanActivate` is a interface with a single function `canActivate(...)`.

```
@Injectable()
export class GuardTest implements CanActivate, CanActivateChild {
  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    return of(true);
  }
}
```

And is used on the route:

```
{
    path: 'guards/:id',
    canActivate: [
      GuardTest
    ]
 }
```

Similarly `CanActivateChild` is a single function `canActivateChild(...)`.

```
@Injectable()
export class GuardTest implements CanActivate, CanActivateChild {

  canActivateChild(childRoute: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    return of(true);
  }
}

```

And can be used on the route:

``` 
{
    path: ':something/guards',
    canActivateChild: [
        GuardTest
    ]
}
```

## 2. Difference

In order to understand the difference, we first need to understand how the router __activate__ a particular route.

Let's consider the following routes:

```
{
    path: 'guards/:something',
    canActivate: [
        GuardTest
    ],
    children: [
        {
            path: ':somethingelse',
            component: GuardComponent,
            canActivate: [
                Guard2Test
            ]
        }
    ]
}
```

This is a single route which when activated, instantiate the GuardComponent.

__The first time /guards/x/y is activated__, `canActivate` from `GuardTest` on the parent `/guards/x` is invoked and then `canActivate` on the child `Guard2Test` get invoked.

From `/guards/x/y`, if we try to activate the route `/guards/s/t`, both guards get activated as if we completely changed route.

From `/guards/x/y`, if we try to activate the route `/guards/x/z`, __the parent will not invoke `canActivate`, only the child `Guard2Test` will get invoked.

__There lies the difference between CanActivate and CanActivateChild.__

If we need to run a guard when __only the child route changes__, we need to use `CanActivateChild`.

```
{
    path: 'guards/:something',
    canActivateChild: [
        GuardTest
    ],
    children: [
        {
            path: ':somethingelse',
            component: GuardComponent,
            canActivate: [
                Guard2Test
            ]
        }
    ]
}
```

`GuardTest` will still run even though coming from `guards/x/y` and trying to activate `guards/x/z`.

## 3. Some considerations

__It used to be possible to redirect using the router within the guard.__ But this behaviour has changed.

Now the guard invoke is expected to complete before any navigation. Meaning the `Observable<boolean>` will need to complete (regardless of the result), in order for a navigation to occur.

For example this following sample will never redirect:

```
canActivate(childRoute: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    // this will never redirect and will get stuck
    this.router.navigate(['/']);
    return Observable.never();
}
```

## 4. Component reusability with router

In 2. we accessed the same route `/guards/:something/:somethingelse` but using different values.

The resulting route displayed the `GuardComponent`.
Angular router is optimized to reuse the same component when the route is re-entered with new data.
The consequence of this behaviour is that the constructor and OnInit function are only called once, the first time the component is instantiated.

Another important point is that a new value is pushed to the `Observable` route params. Therefore is the component is accessible through multiple routes, it is better to use the route params as `Observable` instead of the snapshot. 