# Build a complex form with Angular FormBuilder Reactive form

Few weeks ago I explained how we could build [reactive forms with Angular](https://kimsereyblog.blogspot.sg/2017/06/reactive-form-with-angular.html). In the previous post, I emphasized on how the reactiveness was enabling us to susbscribe to the state and "react" to any state changes. Since then I have been playing quite a bit with the reactive form and more precisely with the `FormBuilder`. I ended up being more impressed by the link between `FormGroup` and UI rendering rather than about the reactiveness nature of the state held by the form. So today I would like to expand more on the `FormBuilder` by showing stepa more complicated form supporting arrays of arrays and different controls like date picker and color picker.

```
1. Building the metadata element form
2. Building the array sections
3. Postback
```

## 1. Building the metadata element

We start with a model which I just made up this model so there is no particular meaning in it.
But what is interesting is that it contains a range, a color, a date and arrays of arrays.

We start first by building the metadata 

Model

Key
Name
Color
Validity
Range int[]
Sections

Section
Name
Keywords