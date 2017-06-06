# Reactive form with Angular

I have been following the reactive movement for a long time now, especially from UI perspective from push design with websockets to in browser reactivity with WebSharper.UI.Next. 
In term of form design, I always felt like there was a lack. A form concept is simple, but it always escalates to an extremely over designed code with inline validation, server validation, incorrect validation at time, multisteps, asynchronous selection, etc...
Something was missing, how the validation was done and how dirty it was to code a proper post back form.

WebSharper was the real first innovation. It came out with a set of combinator that I explained in a [previous blog post] removing the "dirtiness" of form handling.
__It just felt right__. And when things in programming start to feel right, it means you are on the right path.

Since its evolution from 1.x.x, Angular have supports for reactive form with a form builder. Today I will explain the concept and how to use it.

```
1. Create a reactice form with form builder
2. Handle the value changes
3. Validation
```

## 1. Create a reactice form with form builder

The main elements of the form are the 
FormGroup
FormControl
FormArray

Those three elements can be used to create a form. In order to reduce the repetition of creation, we can use the form builder.

Name:
Categories

This.registration : FormGroup

Registration = fb.group({
Name: [''' Validators.required],
Categories: fb.array([])

[formGroup]=registration
FormControlName=name

The form group directive is assigned to the registration which contains the overall form. The formControlName is used to target a particular form control.

Thanks to this approach, we have a cleaner template with an explicit definition of the form field and validation.

The form array in our example is a list of categories.
The benefit of form array is that it is dynamic. We can add or remove from it and it's display will be changed accordingly.
We started with an empty array, if we do have items, we can set them using setControl('categories', [ fb.formControl, ']).
If at any point we need to add more, we can do so with push(fb.formcontrol).

FormArray is an array of form, whether form group or form control. Do not confuse the array with an array of values.

Nested FormGroup
Access nested with dot notation

Setvalue patchvalue

FormArray setControl given control name

Formarray.push

## 2. Handle the value changes

## 3. Validation