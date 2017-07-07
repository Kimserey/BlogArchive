# Managing global state with Ngrx store in Angular

The goal of Angular components is to be completely independent. This can lead to mismatch of displayed data where one component isn't in sync with what other components are displaying. One solution is to have a stateful service shared among all components and delivering global data. This can be problematic when multiple pieces have to be globally accessible among multiple components. In this situation, the need for a global state becomes inevitable.

Global state has had a bad reputation since inception due to its unpredictable nature. 
About two years ago, Redux was introduced as a way to manage this unpredictability by making the state immutable and operations acting on the state synchronous and stateless (a similiar approach can be found in the actor pattern). 
Since then, its principales has inspired multiple implementations, one of them being the Ngrx store for Angular.
Today I will go through the library and build a sample application demonstrating how Ngrx store can be used to share a global state and deliver continuous updates. This post will be composed of 5 parts.

```
 1. Overview
 2. Actions
 3. Reducers
 4. Effects
 5. Selectors and views
```

[https://github.com/ngrx/store](https://github.com/ngrx/store)

## 1. Overview

Our example will be a profile selection. We will have a list of users and on selection, the display will show 2 sections, the user profile and the groups of that user.

Adding a global state using ngrx store is composed by multiple pieces. Some actions defining how the state will be changed, some reducers which are stateless functions "reducing each values of the action payload onto the state", some effects which are used for side effects, like api calls, based on actions produce more actions and lastly the selectors for the views.

Let's start first by adding the necessary libraries:

```
npm install @ngrx/core @ngrx/store --save
```

The effects are optional but in this sample we will be using it:

```
npm install @ngrx/effects --save
```

Lastely the devtools are also optional but I recommend to install them, it will make debugging easier:

```
npm install @ngrx/store-devtools --save
```

Also from Chrome extensions, we can install the [__Redux DevTools__](https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd?hl=en) which allows us to visualize the state and all actions which happened in the system.

## 2. Actions

The actions define what will change the state. In our sample, we will have the following actions:

 - Select user
 - Load profile success
 - Load profile fail
 - Load groups
 - Load groups success
 - Load groups fail

Since loading the values will access an external resource, like an API, we need to cater for failure.
Now in code, an action is defined by a type and a payload where for example Select user will be the type expressed by a string constant and the user Id will be the payload.

```
import { Action } from '@ngrx/store';
import { Profile } from '../models/user';

export const SELECT = '[User] Select';
export const LOAD_PROFILE_SUCCESS = '[User] Load Profile Success';
export const LOAD_PROFILE_FAIL = '[User] Load Profile Fail';

export class SelectAction implements Action {
  readonly type = SELECT;

  constructor(public payload: string) { }
}

export class LoadProfileSuccessAction implements Action {
  readonly type = LOAD_PROFILE_SUCCESS;

  constructor(public payload: Profile) { }
}

export class LoadProfileFailAction implements Action {
  readonly type = LOAD_PROFILE_FAIL;

  constructor(public payload?: any) { }
}

export type Actions
  = SelectAction
  | LoadProfileAction
  | LoadProfileSuccessAction
  | LoadProfileFailAction;
```

And similarly for the groups:

```
import { Action } from '@ngrx/store';
import { Group } from '../models/group';

export const LOAD = '[Group] Load';
export const LOAD_SUCCESS = '[Group] Load Success';
export const LOAD_FAIL = '[Group] Load Fail';

export class LoadAction implements Action {
  readonly type = LOAD;

  constructor(public payload: string) { }
}

export class LoadSuccessAction implements Action {
  readonly type = LOAD_SUCCESS;

  constructor(public payload: Group) { }
}

export class LoadFailAction implements Action {
  readonly type = LOAD_FAIL;

  constructor(public payload?: any) { }
}

export type Actions
  = LoadAction
  | LoadSuccessAction
  | LoadFailAction;
```

## 3. Reducers

The reducers are the handlers of the action. They take in the actions and apply the values of the action payload to the state.
Our state will be composed by two parts, the user state and the group state which will both hold the users and the groups.

### 3.1 Users

For the users, we will hold all user profile.

```
export interface State {
  profile: Profile;
  failure: boolean;
}

export const initialState: State = {
  profile: null,
  failure: false
};
```

The reducer will take the actions we defined earlier:

```
export function reducer(state = initialState, action: user.Actions) {
  switch (action.type) {
    case user.LOAD_PROFILE_SUCCESS: {
      return Object.assign({}, state, {
        profile: action.payload,
        failure: false
      });
    }

    case user.LOAD_PROFILE_FAIL: {
      return Object.assign({}, state, {
        failure: true
      });
    }

    default: {
      return state;
    }
  }
}
```

A reducer takes a state in and an action which it will reduce onto the state.
Here when we receive a load profile success, we set it to the state and reset the failure boolean.

### 3.2 Groups

Similarly for the group reducer, we hold a list of all the groups the user is part of and a boolean indicating failure.

```
export interface State {
  entites: Group[];
  failure: boolean;
}

export const initialState: State = {
  entites: [],
  failure: false
};

export function reducer(state = initialState, action: group.Actions) {
  switch (action.type) {
    case group.LOAD_SUCCESS: {
      return Object.assign({}, state, {
        entites: action.payload,
        failure: false
      });
    }

    case group.LOAD_FAIL: {
      return Object.assign({}, state, {
        failure: true
      });
    }

    default: {
      return state;
    }
  }
}
```

### 3.3 Combined reducer

There is only one reducer in the app, therefore for it to work, we will combine the two reducers into a single reducer.
We do so by creating a combined reducer in a barel `index.ts`.

```
import { compose } from '@ngrx/core/compose';
import { combineReducers } from '@ngrx/store';
import * as fromUser from './user';
import * as fromGroup from './group';

export interface State {
  user: fromUser.State;
  group: fromGroup.State;
}

const reducers = {
  user: fromUser.reducer,
  group: fromGroup.reducer,
};

const combinedReducer = combineReducers(reducers);

export function reducer(state: any, action: any) {
  return combinedReducer(state, action);
}
```

`combineReducers` is a function provided by ngrx store which will direct the correct actions to the correct reducers allowing us to have a clearer code separation.

Lastely we can now register our reducer with the import of the store on our app module using `StoreModule.provideStore(reducer)`.

```
import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpModule } from '@angular/http';
import { StoreModule } from '@ngrx/store';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';

import { AppComponent } from './app.component';
import { reducer } from './reducers';

@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule,
    FormsModule,
    HttpModule,
    StoreModule.provideStore(reducer),
    StoreDevtoolsModule.instrumentOnlyWithExtension(),
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
```

Notice that I also imported the devtools `StoreDevtoolsModule.instrumentOnlyWithExtension()`.

## 4. Effects

Effects handle actions and allows to publish other actions.
They can be used to make calls to APIs and to dispatch appropriate actions based on the result. Essentially we would be calling services within the effects.
Let's start by creating an example service:

```
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs/Observable';
import { of } from 'rxjs/observable/of';
import { Profile } from './models/user';
import { Group } from './models/group';

@Injectable()
export class AppService {
  getUserProfile(userId: string): Observable<Profile> {
    return of(<Profile>{
      userId: userId,
      address: '29 avenue street',
      groups: [ 'group1', 'group2' ],
      name: 'Kim'
    });
  }

  getGroup(userId: string): Observable<Group[]> {
    return of([<Group>{
      groupId: 'group1',
      name: 'Football avenue street'
    }, <Group>{
      groupId: 'group2',
      name: 'Basketball gottam'
    }]);
  }
}
```

Our first effect will be to load user profile when selected:

```
@Injectable()
export class UserEffects {
  @Effect()
  load$: Observable<Action> = this.actions$
    .ofType(user.SELECT)
    .map(toPayload)
    .switchMap(payload => {
      return this.service.getUserProfile(payload)
        .map(profile => new user.LoadProfileSuccessAction(profile))
        .catch(() => of(new user.LoadProfileFailAction()));
    });

  constructor(private actions$: Actions, private service: AppService) { }
}
```

The effect class will receive a list of all actions which we filter with `.ofType`. We then use `toPayload` given by ngrx effects to select the payload of the action and we `.switchMap` to the Observable given by `getUserProfile()`. This in turn produces either a success or failure action.
The flow `.ofType.map.switchMap` is very common and can be found in a lot of other samples.

Similarly for the group effects:

```
@Injectable()
export class GroupEffects {
  @Effect()
  load$: Observable<Action> = this.actions$
    .ofType(group.LOAD)
    .map(toPayload)
    .switchMap(payload => {
      return this.service.getUserProfile(payload)
        .map(groups => new group.LoadSuccessAction(groups))
        .catch(() => of(new group.LoadFailAction()));
    });

  constructor(private actions$: Actions, private service: AppService) { }
}
```

Lastely we can import the effects by adding it in the app module with `EffectsModule.run(XXXEffects)`.

```
@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule,
    FormsModule,
    HttpModule,
    StoreModule.provideStore(reducer),
    StoreDevtoolsModule.instrumentOnlyWithExtension(),
    EffectsModule.run(GroupEffects),
    EffectsModule.run(UserEffects)
  ],
  providers: [AppService],
  bootstrap: [AppComponent]
})
export class AppModule { }
```

## 5. Selectors and views

Now that we have all in place we can build the UI which will use the state by selecting a piece of it.
A function selecting a piece of the state is called a selector. We can make use of redux helper `reselect` which includes some clever caching, memoization and others.

```
npm install reselect --save
```

For example we would need to select the profile from the state. We start by adding the selector in the user reducer file where the state can be found.

```
export const getProfile = (state: State) => state.profile;
```

Next we add a global selector in the barel file containing the concatenated state

```
export const getUserState = (state: State) => state.user;
export const getUserProfile = createSelector(getUserState, fromUser.getProfile);
```

`createSelector` is provided by `reselect`.

Doing so allow us to select a specific piece by creating dedicated selectors.
We can then move on to create the views starting from the containers.
We start by creating a `select-user` container which will provide a dropdown list of users.

```
@Component({
  selector: 'app-select-user',
  template: `
    <select (change)="select($event.target.value)">
      <option value=""> -- Select a user -- </option>
      <option value="joe">Joe</option>
      <option value="kim">Kim</option>
      <option value="mike">Mike</option>
    </select>
  `,
  styles: []
})
export class SelectUserContainer {
  constructor(private store: Store<fromRoot.State>) { }

  select(userId: string) {
    this.store.dispatch(new user.SelectAction(userId));
  }
}
```

When selected, we will broadcast a select action and the state changes to all parties interested with `store.dispatch`.

```
this.store.dispatch(new user.SelectAction(userId));
```

This in turn will trigger the effects which will update the state in the reducers.
We can then create a `profile` container, which will subscribe to the profile state.

```
@Component({
  selector: 'app-user-profile',
  template: `
    <app-profile [profile]="profile$ | async"></app-profile>
  `,
  styles: []
})
export class ProfileContainer implements OnInit {
  profile$: Observable<Profile>;

  constructor(private store: Store<fromRoot.State>) { }

  ngOnInit() {
    this.profile$ = this.store.select(fromRoot.getUserProfile);
  }
}
```

In order to get a piece of the state, we use `store.select` passing it the selector we created previously.
`.select()` is provided by the store, it is important to no confuse it with the Observable.select as this `store.select` will not trigger if the new value is equal to the previous one, meaning on update of the state, this piece will __only__ trigger if the profile is changed.
This container handles the asynchronous portion of the state and extract the result to pass it to a simple component `app-profile` defined as followed:

```
@Component({
  selector: 'app-profile',
  template: `
    <div>
      <strong>Profile</strong>
    </div>
    <dl>
      <dt>Name</dt>
      <dd>{{ profile?.name }}</dd>
      <dt>Address</dt>
      <dd>{{ profile?.address }}</dd>
    </dl>
  `,
  styles: []
})
export class ProfileComponent {
  @Input() profile: Profile;
}
```

This component takes the profile as input which allows to remove the `Observable` and `async` handling.
And that's it, when the user is selected, the changes will be propagated to the profile. 
We do the same for the groups which I'll leave to you!

The full source code is available on my GitHub [https://github.com/Kimserey/ngrx-store-sample](https://github.com/Kimserey/ngrx-store-sample)

# Conclusion

Today we saw how we could manage global state and side effects thanks to Ngrx Store. Managing state has been a problem for some time now, with application growing in complexity on the browser, Ngrx Store definitly helps by bringing a predictable way of updating and sharing global state.
Combined with the effects and the devtools and the power of Observables, it is the right tool to handle state in big projects. Hope you like this post, if you have any question leave it here or hit me on Twitter [Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!