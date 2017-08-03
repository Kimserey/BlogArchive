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

1. How can we ensure that de data is loaded in the page?
2. Where do we load data?

In order to answer those questions, we will first start by modify the sample to require a pre-loading of users before the app can be used.

We start by changing `select-user.ts`.

```
@Component({
  selector: 'app-select-user',
  template: `
    <select (change)="select($event.target.value)">
      <option value=""> -- Select a user -- </option>
      <option *ngFor="let user of users$ | async">{{user}}</option>
    </select>
  `,
  styles: []
})
export class SelectUserContainer implements OnInit {
  users$: string[];
}
```

We then add an action and together with a list of user in the state saved by the reducer. [https://github.com/Kimserey/ngrx-store-sample/commit/13d9eccdf8aef563f40840238c93a02ddb2b3d80](https://github.com/Kimserey/ngrx-store-sample/commit/13d9eccdf8aef563f40840238c93a02ddb2b3d80)

```
export const LOAD_ALL = '[User] Load All';
export const LOAD_ALL_SUCCESS = '[User] Load All Success';
export const LOAD_ALL_FAIL = '[User] Load All Fail';

export class LoadAllAction implements Action {
  readonly type = LOAD_ALL;

  constructor(public payload?: any) { }
}

export class LoadAllSuccessAction implements Action {
  readonly type = LOAD_ALL_SUCCESS;

  constructor(public payload: string[]) { }
}

export class LoadAllFailAction implements Action {
  readonly type = LOAD_ALL_FAIL;

  constructor(public payload?: any) { }
}
```

Then we continue by adding the effect to load a list of users. [https://github.com/Kimserey/ngrx-store-sample/commit/13e1e208850916d989a7d6271152c4ac55505655](https://github.com/Kimserey/ngrx-store-sample/commit/13e1e208850916d989a7d6271152c4ac55505655)

```
@Effect()
loadAll$: Observable<Action> = this.actions$
    .ofType(user.LOAD_ALL)
    .switchMap(() => {
        return this.service.getAll()
        .map(users => new user.LoadAllAction(users))
        .catch(() => of(new user.LoadAllFailAction()));
    });
```

And we finish with the reducer with the selector. 
[https://github.com/Kimserey/ngrx-store-sample/commit/e55f1ca7f5e7e9854a6e45fda63b88e61f96576e](https://github.com/Kimserey/ngrx-store-sample/commit/e55f1ca7f5e7e9854a6e45fda63b88e61f96576e)

```
export interface State {
  users: string[];
  profile: Profile;
  failure: boolean;
}

export const initialState: State = {
  users: [],
  profile: null,
  failure: false
};

export function reducer(state = initialState, action: user.Actions) {
  switch (action.type) {
    case user.LOAD_ALL_SUCCESS: {
      return Object.assign({}, state, {
        users: action.payload
      });
    }

    ...
  }
}
```

## 2. Route guard

A guard is a service implementing `CanActivate`. It will be registered on the route. `CanActivate` expects the implementation of a single function `canActivate` which returns a boolean or a promise of a boolean or an observable of boolean. In the case of observable on once the observable completes will the guard take the last item to decide whether the user can or not access the component.

In our case what we want is to:
 1. Check if the users are loaded
 2. If no, dispatch `new user.LoadAllAction()`
 3. Wait till the users are loaded to allow showing the page

This logic translate to the following guard:

```
@Injectable()
export class UserLoadedGuard implements CanActivate {
  constructor(private store: Store<fromRoot.State>) { }

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    
    // 1
    const isLoaded$ = this.store.select(fromRoot.getUsers)
      .map(users => users.length > 0);

    // 2
    isLoaded$
      .take(1)
      .filter(loaded => !loaded)
      .map(() => new user.LoadAllAction())
      .subscribe(this.store);

    // 3
    return isLoaded$
      .take(1);
  }
}
```

Then we can add this guard as a provider.

```
@NgModule({
  ...
  providers: [
    UserLoadedGuard,
    ...
  ]
})
export class AppModule { }
```

## 3. Usage

Now that we have the guard, we can use it in the route definition to protect the component.

```
export const routes: Routes = [
  {
    path: '',
    canActivate: [UserLoadedGuard],
    component: MainContainer,
    children: [{
        path: ':userId',
        component: UserContainer
    }]
  }
];
```

Now everytime we navigate to the application, the guard will be excuted and the users will be loaded.

__Why is it important?__

Utilizing a guard has multiple advantages:

 - The first one is that the code to ensure that the data is loaded is reusable. The guard can be placed in front of any route which needs to load all users. It will ensure that the users are loaded before someone navigate to the route via other path or via direct browser access.
 - The second advantage is that we can now make the assumption that the users will be loaded before the entrance of the code in the component. Knowing that makes a big difference as we can write component code which doesn't need to care about preloading data hence the component code is simpler.
 - The  third advantage is that it can be followed as a universal guideline to place preloading data code in guard. This will allow a superior maintenable code as it will be easy to find where the loading is even after few months of not touching the code.
 - The fourth and last advantage is that a guard was created to ensure that data is loaded before showing a page which fit exactly with our purpose. Therefore the code in the `canActivate` is very simple and easily understood.
 
# Conclusion