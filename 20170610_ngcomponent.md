# How to declare a component in angular

Last week I explained what was the NgModule in angular, we saw what were the parameters we could add and what those parameters could be composed of.
Today I would like to talk about another main piece of Angular, the Component.
We will see what argument it takes and how we can use it.

```
1. Parameters
2. Input/Ouput
3. Access child component
4. NgOnChange
```

## 1. Parameters

Selector to use the component
Styles for inline style in the component
Template for inline template
StyleUrls for list of files with css
TemplateUrl for a reference to a template file
Providers for optional providers scoped to the component.

## 2. Input/Output

The `@Input()` decorator is used to specify the argument which the component expect the parent to pass in.

The `@Output()` decorator is used to bind an EventEmitter which dispatch events from within the component to notify the parent of changes. Doing that allows the component to not have any reference to the parent.

## 3. Access child component

It is also possible to use a template variable to get a reference to the component from the parent template and call the component actions.

```
```

This is limited for usage within the template. If we need to have access to the child within the component, we can use ViewChild.