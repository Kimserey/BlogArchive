# How to declare a component in angular

Last week I explained what was the NgModule in angular, we saw what were the parameters we could add and what those parameters could be composed of.
Today I would like to talk about another main piece of Angular, the Component.
We will see what argument it takes and how we can use it.

```
1. Parameters
2. Input/Ouput
3. Access child component
4. NgOnChange
````

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
    @Input() side: number;
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

`Input` and `Output` are set during the init life cycle of a component. Therefore If you wish to perform any action using the inputs or outputs values, you will need to implement `OnInit` and perform your action within the `ngOnInit(){}` life cycle hook.

## 3. Access child component

It is also possible to use a template variable to get a reference to the component from the parent template and call the component actions.

```
<app-square #square></app-square>
{{square.side}}
```

With `#square` we can get access to component from the parent template and use it.
This is limited for usage within the template. 
If we need to have access to the child within the component, we can use `ViewChild` which allows us to access a component. It will only return the first element matching the component selector.

```
@ViewChild(SquareComponent) square: SquareComponent;
```

In order to use it, we need to implement the `AfterViewInit` interface single function `ngAfterViewInit()` which the callback which occurs directly after the `ViewChild` is set.
But if we need to modify members displayed in the template, we will need to set a timer for it otherwise we will face some `Value changed after check` error.

```
@Component({
  selector: 'app-root',
  template: `
    <app-square [show]="true" [side]="4" #square></app-square>
    <app-square [show]="true" [side]="5"></app-square>
    <strong>{{surface}}</strong>
  `
})
export class AppComponent implements AfterViewInit  {
  @ViewChild(SquareComponent) square: SquareComponent;

  surface = 0;

  ngAfterViewInit() {
    setTimeout(() => this.surface = this.square.surface, 0);
  }
}
```

## 4. NgOnChange

In order to communicate changes from parent to child, it is also possible to implement the `OnChange` life cycle hook.

_Do not confuse the on-change or (change) DOM event binding with the `OnChange` life cycle hook._

When one of the input changes, the `ngOnChanges(changes: SimpleChanges){}` callback will be called.

`SimpleChanges` is a dictionary defined by angular:

```
export interface SimpleChanges {
    [propName: string]: SimpleChange;
}
```

Where a `SimpleChange` contains information about the change itself:

```
export declare class SimpleChange {
    previousValue: any;
    currentValue: any;
    firstChange: boolean;
    /**
     * Check whether the new value is the first value assigned.
     */
    isFirstChange(): boolean;
}
```

Using that we can detect changes in our SquareComponent example to recompute the surface:

```
export class SquareComponent implements OnChanges {
  @Input() side: number;

  ngOnChanges(changes: SimpleChanges) {
    // the value already changed
    this.computeSurface();

    console.log(`side previous value: ${changes['side'].previousValue}, side current value: ${changes['side'].currentValue}`);
  }
  
  private computeSurface() {
    this.surface = this.service.computeSurface(this.side);
  }
```

This method is useful when many input can be changed and we wish to handle all changes in one single place and we need to know the details of the change, previous value and current value.

__Setter and getter__

Otherwise a simpler approach in handling changes would be to define a setter on the input:

```
@Input() set side(s: number) {
    this._side = s;   
}
get side() {
    return this._side;
}
```

We can then intercept the change in the setter to perform an action.

# Conclusion

Today we saw how we could define angular components. We saw how we could communicate between parent and child. Components need to be kept as simple as possible and must be broken down into small pieces. 
Communication must be taken very seriously into consideration as it can easily degenerate into an unmaintainable solution where changes become extremely hard to track.
I hope you enjoyed this post as much as I enjoyed writing it, if you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam), see you next time!