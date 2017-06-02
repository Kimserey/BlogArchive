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

Component in Angular derives from directives. Some of the most used properties are:
- `providers` which defines a injectable values or services scoped only by the component and its children (compared to injectable provided to the module which is application wide)
- `selector` which defines a CSS selector to use the component

Here are some of the parameter used to defined a component:
- `styles` for inline style in the component
- `template` to define inline template

For example here is a simple component:

```
@Component({
  selector: 'app-square',
  template: '<div></div>',
  styles: [ '.square { width:100px; }'
  ]
})
export class SquareComponent {}
```

We can then use it in a parent component:

```
<app-square></app-square>
```

Instead of `template`, `templateUrl` can be used to use a template file. Also to define style, we can also specify files using `styleUrls`.

## 2. Input/Output

In order to communicate, a component can make use of the input and ouput decorators.

The `@Input()` decorator is used to specify the argument which the component expect the parent to pass in.
It will be passed by binding from the parent to the component.

```
<app-square [side]="4"></app-square>
```

Notice that we used `[]` which is the one-way from data source to view target, the source being the right side of `=` and target being the left side.

In the component then we can use this decorator like so:

```
export class SquareComponent {
    @Input() square: number;
}
```

The `@Output()` decorator is used to bind an `EventEmitter` which dispatch events from within the component to notify the parent of changes. Doing that allows the component to not have any reference to the parent.

```
<app-square (modified)="onModified($event)"></app-square>
```

Notice that we used `()` which is the one-way from view target to data source.

We can then use the decorator like so:

```
export class SquareComponent {
    @Output() modified = new EventEmitter<number>();

    modify(n) {
        this.modified.emit(n);
    }
}
```

Then in the parent:

```
export class SquareParentComponent {
    onModified(n) {
        // do something
    }
}
```

Using input and output we can then handle inputs passed down to the component and outputs coming out of the component from the `EventEmitter`.

## 3. Access child component

It is also possible to use a template variable to get a reference to the component from the parent template and call the component actions.

```
```

This is limited for usage within the template. If we need to have access to the child within the component, we can use ViewChild.