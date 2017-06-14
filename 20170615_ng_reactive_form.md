# Reactive form with Angular

I have been following the reactive movement for a long time now, especially from UI perspective from push design with websockets to in browser reactivity with WebSharper.UI.Next. 
In term of form design, I always felt like there was a lack. A form concept is simple, but it always escalates to an extremely over designed code with inline validation, server validation, incorrect validation at time, multisteps, asynchronous selection, etc...
Something was missing, how the validation was done and how dirty it was to code a proper post back form.

WebSharper was the real first innovation. It came out with a set of combinator that I explained in a [previous blog post] removing the "dirtiness" of form handling.
__It just felt right__. And when things in programming start to feel right, it means you are on the right path.

Since its evolution from 1.x.x, Angular have supports for reactive form with a form builder. Today I will explain the concept and how to use it.

```
1. Create a reactice form with form builder
2. Setting values and submitting
3. Validation
```

## 1. Create a reactice form with form builder

All the directives are provided by the `ReactiveFormsModule` module which can be imported from `@angular/forms`.
In order to create a form, we have access to three main elements; `FormGroup`, `FormControl` and `FormArray`.
- `FormGroup` is used to group single elements or a set of elements together.
- `FormControl` is used to represent a single element control.
- `FormArray` is used to represent a dynamic set of `FormGroup`, therefore a dynamic set of fields or set of set of field.

To build and manipulate a form, Angular provides us a `FormBuilder` which is provided by the `ReactiveFormsModule` and can be injected in constructor.

```
constructor(private fb: FormBuilder) {
    const ingredients = [ 'carrot', 'beans' ];
    const ingredientFromGroups = ingredients.map(i => fb.group({ ingredientName: i }));

    this.recipeForm = fb.group({
        profile: fb.group({
            name: ['', Validators.required ],
            timeEstimation: ''
        }),
        ingredients: fb.array(ingredientFromGroups)
    });
}
```

Then in our template we can have the following:

```
<form [formGroup]="recipeForm">
  <div formGroupName="profile">
    <label>Recipe name</label>
    <input type="text" formControlName="name" />
    <label>Estimation</label>
    <input type="text" formControlName="timeEstimation" />
  </div>

  <div formArrayName="ingredients">
    <div *ngFor="let ingredient of ingredients.controls; let i=index" [formGroupName]="i">
      <label>#{{ i }} Ingredient</label>
      <input type="text" formControlName="ingredientName" />
    </div>
  </div>
</form>
```

[fromGroup] directive is meant to be used for the top level form.
[formControl] is meant to be used for a top level single control element.
`formControlName` is used to indicate a `dot notation`.
`xxxName` is used to provide `dot notation`. There is also `formGroupName` and `formArrayName`.

```
[formGroup]="myForm"
 - formControlName="something"
``` 

This will find `myForm.something`. Similarly if we have nested form groups, `formGroupName` can be used.

```
[formGroup]="myForm"
 - formGroupName="something"
   - formControlName="else"
``` 

This will find the value for the control `myForm.something.else`.

The `FormArray` is slightly different. It is a array of group or control. It is there to cater for dynamic fields or group of fields. For example here we have a dynamic list of ingredients.

```
const ingredients = [ 'carrot', 'beans' ];
const ingredientFromGroups = ingredients.map(i => fb.group({ ingredientName: i }));
```

We are creating a list of groups with a single `ingredientName` control. To display that we need to provide the `dot notation` by using the `formArrayName="ingredients"`. Then under it we can use `*ngFor` and iterate over the `ingredients.controls`.

Also the __index is needed to target a control in the form array__, so we need to use `let i=index"` and `[formGroupName]="i"`. `[formGroupName]` is special case where `[]` is needed as it is contained within the array. Under it, we use `formGroupName` and `formControlName`.

```
  <div formArrayName="ingredients">
    <div *ngFor="let ingredient of ingredients.controls; let i=index" [formGroupName]="i">
      <label>#{{ i + 1 }} Ingredient</label>
      <input type="text" formControlName="ingredientName" />
    </div>
  </div>
```

The benefit of the form array is its dynamic nature. We can push and remove control from the form. For example we could add a `add` button and `remove` button:

```
  <button (click)="addIngredient()">Add another ingredient</button>
  <div formArrayName="ingredients">
    <div *ngFor="let ingredient of ingredients.controls; let i=index" [formGroupName]="i">
      <label>#{{ i + 1 }} Ingredient</label>
      <input type="text" formControlName="ingredientName" />
      <button (click)="removeIngredientAtIndex(i)">-</button>
    </div>
  </div>
```

And add `addIngredient` and `removeIngredientAtIndex`.

```
  addIngredient() {
    this.ingredients.push(this.fb.group({
        ingredientName: 'new ingredient'
    }));
  }

  removeIngredientAtIndex(index) {
    this.ingredients.removeAt(index);
  }
```

## 2. Setting values and submitting

When our input changes it is also possible to change the content of any control using `setValue` or `patchValue`. `setValue` is used to set all values for the control while `patchValue` is used to set a part of the values. `setValue` will crash if not all the values are provided.

Those functions are available from the `AbstractControl`.

```
this.recipeForm.get('profile').setValue({ lastName: '', firstName: '' });
this.recipeForm.get('profile').patchValue({ firstName: '' });
```

We can also observe any changes of values in the form using `valueChanges` and a side effect function like `forEach` or `subscribe`.

```
this.recipeForm
  .valueChanges
  .forEach(c => console.log(JSON.stringify(c)));
```

Any abstract control can be observed. This makes it easy to show a live preview of the info or a show a status as we can subscribe to any changes of the overall form.

To submit the form, the same method as template form is used with a `ngSubmit` and a button with type submit. We can have access to all the values with the property `form.value` and also access the form status with `form.valid/pristine/dirty/etc..`.

```
<form [formGroup]="recipeForm" (ngSubmit)="save()">
  <!-- some other controls -->
  <button type="submit" [disabled]="!recipeForm.valid">Submit</button>
</form>
```

Be sure to make a deep copy of the objects and arrays within the form in order to not expose a reference of our form model to other components.

## 3. Validation

We saw how to construct an entire form without validation. Of course the server side will validate but it is always nice to prevent the user from even submitting the form and guide as much as possible to ease the process of filling up the form.

Validators can be applied to a single control or to a group of control as both implement the abstraction `AbstractControl`.

For a single control, the `Validators` gives access to some already built in validations:

- required
- email
- min length
- max length
- pattern
- and a no-op validator `nullValidator`

Those default validators can be applied any form control. Multiple validators can be given as array.

```
name: [ '', [ Validators.required, Validators.pattern('carrot') ] ],
```

The array (or tuple) notation takes the `value` as first element, a `validator` as second argument and an `async validator` as last.

The source code which create the control can be found on `forms.js`:

```
else if (Array.isArray(controlConfig)) {
    const /** @type {?} */ value = controlConfig[0];
    const /** @type {?} */ validator = controlConfig.length > 1 ? controlConfig[1] : null;
    const /** @type {?} */ asyncValidator = controlConfig.length > 2 ? controlConfig[2] : null;
    return this.control(value, validator, asyncValidator);
}
```

Our validator previously defined ensures that the value isn't `null` and that the string must be `carrot`.

__We return `null` if the control is valid, it will pass to the next validator.__

If we need to apply a validation on multiple control, we need to create a custom validator and apply it to a group.
To do that we can implement the function definition `ValidationFn`.

```
function nameValidator(nameKey: string, descriptionKey: string): ValidatorFn {
  return (control: AbstractControl): {[key: string]: any} => {
    const fg = control as FormGroup;
    const name = fg.get('name').value;
    const description = fg.get('description').value;
    return name.length > description.length ? { 'descriptionTooSmall': {name, description}} : null;
  };
}
```

For example here we verify that the description is longer than the name. This check spans accross two controls. In order to use it, we need to pass it to the formbuilder `group` function as followed:

```
fb.group({
  name: '',
  description: '',
  timeEstimation: ''
}, {
  validator: nameValidator('name', 'description')
})
``` 

The `validator` is passed as `extra`, the code can be found in the `forms.js` where we see that the extra can accept a validator or an async validator:

```
group(controlsConfig, extra = null) {
    const /** @type {?} */ controls = this._reduceControls(controlsConfig);
    const /** @type {?} */ validator = extra != null ? extra['validator'] : null;
    const /** @type {?} */ asyncValidator = extra != null ? extra['asyncValidator'] : null;
    return new FormGroup(controls, validator, asyncValidator);
}
```

This sort of validation can be also useful in a password/confirm-password check.