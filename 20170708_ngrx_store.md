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

export const initialState: State {
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

export const initialState: State {
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