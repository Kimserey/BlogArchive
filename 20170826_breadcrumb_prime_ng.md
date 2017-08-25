# Implement a breadcrumb in Angular with PrimeNg

The breadcrumb is a very important piece of any website. It gives an idea where the user is currently in, from where the user landed on this page and finally allow the user to navigate back to any steps wanted.
I like to call it an "enhanced version of the URL path". The URL path in itself has the information but it might, at time, not be human readable. That is where the breadcrumb become indispensable.
I showed few features of PrimeNg in my previous posts [about building an inline form](https://kimsereyblog.blogspot.com/2017/08/inline-form-angular-and-primeng.html) and [about building a tree structure](https://kimsereyblog.blogspot.com/2017/07/tree-structure-in-angular-with-primeng.html). It turns out that they also provide a Angular friendly breadcrumb component.
Today we will see how we can make use of the breadcrumb component together with the Angular router to provide a breadcrumb bar.
This post is composed by 3 parts:

```
1. PrimeNg Breadcrumb component
2. Breadcrumb service, parent/child component communication
3. Use the breadcrumb service together with the PrimeNg Breadcrumb component
```

## 1. PrimeNg Breadcrumb component

Just like other components from PrimeNg, the breadcrumb component comes from a separate module called `BreadcrumbModule` and each breadcrumb element is defined as a `MenuItem` like any other menu. So we need to import those in the module we need to use the breadcrumb.

```
@NgModule({
  imports: [
    BreadcrumbModule
    ...
  ],
  ...
})
export class MyModule { }
```

All we have to do is simply to use the breadcrumb:

```
<p-breadcrumb [model]="crumbs"></p-breadcrumb>
```

And in our component:

```
export class PrimeNgComponent implements OnInit {
  crumbs: MenuItem[];
    
  ngOnInit() {
    this.crumbs = [
        { label: 'Home' },
        { label: 'Products' },
        { label: 'Product A' }
    ];
  }
}
```
`model` binds to our property `crumbs` in our component and we can push `MenuItem` in it on initialization. The result is as followed:

![preview]()

Now that we have a breadcrumb component working, what we have left to do is to use it from our pages and update it accordingly to the current page we navigated to.

## 2. Breadcrumb service, parent/child component communication

In order to update the breadcrumb, we can directly update the crumbs on `ngOnInit` of each components. But this would mean having to add the breadcrumb in every pages. What we can do instead is create a _parent_ component, which will hold the breadcrumb and then from each _child_ components, update the breadcrumb depending on which _child_ is active. For this to work, we need a `Breadcrumb service` to communicate the current position back to the parent.

Here's a preview of the implementation:

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

The `Breadcrumb` service contains a `crumbs$` observable which will change based on the current active route.
It has a function `setCrumbs` which will be used on the active route component to dispatch a new item to the `crumbs$` observable.

Notice the `routerLinkActiveOptions: { exact: true }` option which makes only the exact path active for the router. This is to prevent all the crumbs to be seen as visually active.

Now that we have the service, we can move on to the components implementations.

## 3. Use the breadcrumb service together with the PrimeNg Breadcrumb component

In a previous post, I explained [how the Angular router works and how routes are defined](https://kimsereyblog.blogspot.com/2017/06/how-to-use-angular-router.html).

Here we want a parent component which will hold the breadcrumb:

```
@Component({
  template: `
    <div class="m-3">
      <p-breadcrumb [model]="crumbs$ | async"></p-breadcrumb>
    </div>
    <router-outlet></router-outlet>
  `
})
export class ParentComponent implements OnInit {
  crumbs$: Observable<MenuItem[]>;
    
  constructor(private breadcrumb: BreadcrumbService) { }

  ngOnInit() {
    this.crumbs$ = this.breadcrumb.crumbs$;
  }
}
```

Then we can place it as a parent route for our components:

```
const routes: Routes = [
  {
    path: '',
    component: ParentComponent,
    children: [{
      path: 'my-route',
      component: MyComponent,
    }],
  }
];
```

Now we should be able to see the breadcrumb when navigating to `/my-route`.
Next we need to be able to update the breadcrumb when `MyComponent` is activated.

```
@Component({
  template: `
    <p class="m-3">This component is breadcrumb'ed</p>
  `
})
export class MyBreadcrumbedComponent implements OnInit {
  constructor(private breadcrumb: BreadcrumbService) { }

  ngOnInit() {
    setTimeout(() =>
      this.breadcrumb.setCrumbs([{
        label: 'A'
      }, {
        label: 'B'
      }, {
        label: 'C'
      }])
    );
  }
}
```

You might be wondering, __what is the setTimeout about?__
The `setTimeout` is meant to delay the cycle of update for the breadcrumb.
As we saw, the crumbs are directly displayed in the parent. Because of the change cycle ran by Angular, the parent data are evaluated first, at that point, the breadcrumb was empty. Then once the child component is evaluated, it pushes data to update the breadcrumb __which has already been evaluated__.
This causes the following exception:

```
ERROR Error: ExpressionChangedAfterItHasBeenCheckedError: Expression has changed after it was checked. Previous value: '[object Object]'. Current value: '[object Object],[object Object],[object Object]'.
```

In order to fix this, we simply delay the update to the end of the change cycle using `setTimeout`.

And that's it, we have now a workable breadcrumb. More enhancement can be made, for example, we can make a common base class which will be used by all components needing to update the breadcrumb and we could add the menu items straight into the route data so that no code would be needed on the component. Lastly we could implement a token replacement mechanism in order to allow the route labels to use values from the params of the activated route but I will leave that for you to implement!

# Conclusion

