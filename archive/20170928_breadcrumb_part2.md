# Implement a breadcrumb in Angular part 2

Last month I showed how we could [build a breadcrumb with PrimeNG in Angular](https://kimsereyblog.blogspot.sg/2017/08/implement-breadcrumb-in-angular-with.html) (you can read it as appetizer if you are interested in implementing a breadcrumb bar). In my previous post, I suggested to have a service `BreadcrumbService` which would hold the crumbs and get updated in `ngOnInit` of the component used on the route. Since then, I always was uncomfortable with this approach as this meant that __my component would know the existance of a breadcrumb, because it updates it, while I always believed it should not know and not care__.
This led me to figure another way __to abstract away from the component the concept of breadcrumb__ by combining guard, resolver and route. It can be achieved with the following 3 steps:

```
1. Register your crumbs as route data
2. Create a guard which ensure sets the crumbs on the service before page is shown
3. Change the breadcrumb service to use a ReplaySubject instead of Subject
```

## 1. Register your crumbs as route data

Registering data on the route is an easy way to inject constant data into the activated route.
The activated route can then be injected anywhere in all elements under the route like a component, a resolver or a guard.

For example if our route needs the following breadcrumb:

```
Item1 > Item2 > Item3
```

We can add the data in the route as followed:

```
{
    path: 'breadcrumb2',
    component: MyBreadcrumbed2Component,
    data: {
        crumbs: [{
            label: 'test1'
        }, {
            label: 'test2'
        }, {
            label: 'test3'
        }]
    }
}
```

## 2. Create a guard which ensure sets the crumbs on the service before page is shown

What we've done in the previous post was to create a service holding the crumbs:

```
@Injectable()
export class BreadcrumbService {
  private crumbs: Subject<MenuItem[]>;
  crumbs$: Observable<MenuItem[]>;

  constructor() {
    this.crumbs = new Subject<MenuItem[]>();
    this.crumbs$ = this.crumbs.asObservable();
  }

  setCrumbs(items: MenuItem[]) {
    this.crumbs.next(
      (items || []).map(item =>
          Object.assign({}, item, {
            routerLinkActiveOptions: { exact: true }
          })
        )
    );
  }
}
```

Before our page is shown, we want the breadcrumb to be filled up. Therefore we need to set it. The ideal place to do that is in a guard by implementing CanActivate as we make sure that we set the crumbs before returning true:

```
@Injectable()
export class BreadcrumbInitializedGuard implements CanActivate {

  constructor(private service: BreadcrumbService) { }

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    const crumbs = route.data['crumbs'];
    this.service.setCrumbs(crumbs);
    return true;
  }
}
```

And we add it to the route:

```
{
    path: 'breadcrumb2',
    component: MyBreadcrumbed2Component,
    canActivate: [ BreadcrumbInitializedGuard ],
    data: {
        crumbs: [{
            label: 'test1'
        }, {
            label: 'test2'
        }, {
            label: 'test3'
        }]
    }
}
```

## 3. Change the breadcrumb service to use a ReplaySubject instead of Subject

If you test what we done so far, the application should run but you will notice that the breadcrumb is not filled up. 
The observable returns nothing even though the crumbs are set in the guard.

The reason is that the subscription to the crumbs in the component happens after the crumbs are set which means it will never get passed to the subscription as it is the past.

What we need is to replay the stream on subscription. To do that we can use the `ReplaySubject`.

```
@Injectable()
export class BreadcrumbService {
  private crumbs: ReplaySubject<MenuItem[]>; // <-- Change to ReplaySubject
  crumbs$: Observable<MenuItem[]>;

  constructor() {
    this.crumbs = new ReplaySubject<MenuItem[]>();
    this.crumbs$ = this.crumbs.asObservable();
  }

  setCrumbs(items: MenuItem[]) {
    this.crumbs.next(
      (items || []).map(item =>
          Object.assign({}, item, {
            routerLinkActiveOptions: { exact: true }
          })
        )
    );
  }
}
```

And we are done, we now have a component without knowledge of the breadcrumb.

The full source code is available in my GitHub [https://github.com/Kimserey/ng-samples/blob/master/src/app/primeng/prime-ng.module.ts](https://github.com/Kimserey/ng-samples/blob/master/src/app/primeng/prime-ng.module.ts).

# Conclusion

Today we revisited our implementation of the breadcrumb bar. We made use of the tools provided by Angular router to abstract away the concept of navigation out of the component implementation. This technique of combining guard and service can be used in many scenarios where initialization is required. Hope you enjoyed this post as much as I enjoyed writting it. If yoy have any questions leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!