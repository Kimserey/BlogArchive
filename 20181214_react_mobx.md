# Create React App with Mobx in Typescript

I have been using state management frameworks for the past few years, mainly with [Angular](https://kimsereyblog.blogspot.com/search/label/Angular) and [NGRX](https://kimsereyblog.blogspot.com/search/label/ngrx). Today we will see how we can get started with `Create-React-App` using `Mobx` as a state management system.

1. Bootstrap a fresh application
2. Create a component
3. Create an observable state / store
4. Create observers containers

## 1. Bootstrap a fresh application

Start by installing the latest version of NPM then use `npx` to setup a fresh project.

```
npx create-react-app my-app --typescript
```

Then navigate to `/my-app` and run `npm start`. This will start the application in a development server with a live reload. The command run by `npm start` is defined under `package.json` `scripts > start` and runs `react-scripts start`.

```
cd my-app
npm start
```

The application should now build and run properly and any changes done on the application should be reflected on the browser. We now have all the necessary tool to start writing code in React.

## 2. Create a component

In React with Typescript, creating a component can be done in two ways,

1. using a class
2. creating a function

Using a class, we need to inherit from `React.Component` and implement the `render()` function which returns a `JSX.Element`. While creating a function would just be a function that takes `()` or `props` as argument and returns a `JSX.Element`.

```
import React, { Component } from 'react';

export class HelloWorld extends Component {
  render() {
    return (
      <div>Hello World</div>
    );
  }
}
```

or as a function:

```
const ByeBye = () => {
  return (
    <div>Bye bye</div>
  );
}
```

Then we can use both of them in `App.tsx`:

```
class App extends Component {
  render() {
    return (
      <div>
        <HelloWorld/>
        <ByeBye/>
      </div>
    );
  }
}
```

We can see how we use the component by directly using the component as a tag name `<HelloWorld/>` or `<ByeBye/>`.
If we want to pass argument from parent component to child component, we use `props`. In Typescript, we can typesafe the prop by specifying it in the component class `Component<TProps>`.

```
export class HelloWorld extends Component<{ user: string }> {
  constructor(props: { user: string }) {
    super(props);
  }
  
  render() {
    return (
      <div>Hello World {this.props.user}</div>
    );
  }
}
```

Notice that we get the `props` from the constructor and forward it to the base component `super(props)`. After that we have to specify `user` on the component in `App`.

```
<HelloWorld user="Kim"/>
```

React was called react at the first place because it introduces a reactive approach (ok I might have made up that one but I guess that's the reason).
Now if we define a variable in our component:

```
class App extends Component {
  user = "Kim";

  onUserChange = (e: ChangeEvent<HTMLSelectElement>) => {
    this.user = e.target.value;
  }

  render() {
    return (
      <div>
        <select value="Kim" onChange={this.onUserChange}>
          <option value="Kim">Kim</option>
          <option value="Tom">Tom</option>
          <option value="Sam">Sam</option>
        </select>
        <HelloWorld user={this.user}/>
      </div>
    );
  }
}
```

We will see that the component only gets rendered once displaying `Kim` once. The reason is that each component have an internal state. Changing the component state will trigger a rerendering. This state can be access with `this.state` and can be typesafe as well from `Component<any, TState>`.

```
class App extends Component<any, { user: string }> {
  constructor(props: any) {
    super(props);

    this.state = { user: "Kim" };
  }

  onUserChange = (e: ChangeEvent<HTMLSelectElement>) => {
    this.setState({ user: e.target.value });
  }

  render() {
    return (
      <div>
        <select value="Kim" onChange={this.onUserChange}>
          <option value="Kim">Kim</option>
          <option value="Tom">Tom</option>
          <option value="Sam">Sam</option>
        </select>
        <HelloWorld user={this.state.user}/>
      </div>
    );
  }
}
```

Notice the lambda expression set for the event handler. We do that to capture the context of `this` to the current class.
Here what we do is that we've typesafe the state with `{ user: string }` and called `setState()` changing the `user` property of the state. When the selection changes, `HelloWorld` gets rendered with the right value.

We can also go a step further and define our `HelloWorld` component as `PureComponent` providing a performance boost. A component can be defined as pure when for the same set of `props`, it yields the same rendering.

```
export class HelloWorld extends PureComponent<{ user: string }> {
  constructor(props: { user: string }) {
    super(props);
  }
  
  render() {
    return (
      <div>Hello World {this.props.user}</div>
    );
  }
}
```

State is great for a single component and simple scenario, but when our application involves a more complex state which needs to be shared across multiple components, we can introduce a state management framework.

## 3. Create an observable state / store

The state management we will be using is `Mobx`. We start first by installing it.

```
npm install mobx --save
```

Next we 
