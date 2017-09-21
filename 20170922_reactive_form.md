# Build a complex form with Angular FormBuilder Reactive form

Few weeks ago I explained how we could build [reactive forms with Angular](https://kimsereyblog.blogspot.sg/2017/06/reactive-form-with-angular.html). In the previous post, I emphasized on how the reactiveness was enabling us to susbscribe to the state and "react" to any state changes. Since then I have been playing quite a bit with the reactive form and more precisely with the `FormBuilder`. I ended up being more impressed by the link between `FormGroup` and UI rendering rather than about the reactiveness nature of the state held by the form. So today I would like to expand more on the `FormBuilder` by showing the steps needed to build a more complicated form supporting arrays of arrays and different controls like date picker and color picker. This post will be composed by 3 parts:

```
1. Building the metadata element form
2. Building the array sections
3. Postback
```

## 1. Building the metadata element

We start with a model which I just made up this model so there is no particular meaning in it.

```
interface Model {
  name: string;
  color: string;
  validity: Date;
  range: number[];
  choice: string;
  sections: {
    sectionName: string;
    keywords: string[];
  }[];
}
```
What is interesting is that it contains a range, a color, a date and arrays of arrays.
We start first by building the metadata 

```
name: string;
color: string;
validity: Date;
range: number[];
choice: string;
```

For the name we will use a simple html text input but for the rest, in order to provide the best user experience, we can make use of PrimeNg components:
 - for the color we will be importing the `ColorPickerModule`,
 - for the validity date we will be importing the `CalendarModule`,
 - for the range we will be importing the `SliderModule`,
 - lastly for the choice we will be importing the `DropdownModule`.

```
import { CalendarModule, ColorPickerModule, DropdownModule, SliderModule } from 'primeng/primeng';

@NgModule({
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    CalendarModule,
    ColorPickerModule,
    DropdownModule,
    SliderModule
  ],
  declarations: [
    ComplexComponent,
  ]
})
```

### Text input

We start first by the basic:
 - define the form
 - define the simplest element, the name text input

```
<div class="p-3">
    <form [formGroup]="form">
        <div class="form-group row">
            <label for="name" class="col-sm-3 col-form-label">Name</label>
            <div class="col-sm-9">
            <input id="name" type="text" class="form-control" formControlName="name" placeholder="Enter name" />
            </div>
        </div>
    </form>
</div>
```

For the component, we define a `FormGroup` containing the whole form and we instantiate it using the `FormBuilder` `group()` function.
[More explanation can be found on my previous blog post on Reactive forms.](https://kimsereyblog.blogspot.sg/2017/06/reactive-form-with-angular.html)

```
export class ComplexComponent implements OnInit {
  form: FormGroup;

  constructor(private fb: FormBuilder) {
  }

  ngOnInit() {
    this.form = this.fb.group({
      name: ['']
    });
  }
}
```

### ColorPicker

To add a color picker input, we use the `ColoPicker` component from PrimeNg.

```
<div class="p-3">
    <form [formGroup]="form">
        <div class="form-group row">
            <label for="name" class="col-sm-3 col-form-label">Name</label>
            <div class="col-sm-9">
                <input id="name" type="text" class="form-control" formControlName="name" placeholder="Enter name" />
            </div>
        </div>
        <div class="form-group row">
            <label for="color" class="col-sm-3 col-form-label">Color</label>
            <div class="col-sm-9">
                <p-colorPicker formControlName="color"></p-colorPicker>
            </div>
        </div>
    </form>
</div>
```

`ColorPicker` works with 2-way bindings with `ngModel` but notice that it can also be used with `formControlName="color"` like how we did to fill up the value of a reactive form.
Note that if we forget to add `BrowserAnimationsModule` we will be presented with the following error:

```
Found the synthetic property @panelState. Please include either "BrowserAnimationsModule" or "NoopAnimationsModule" in your application.
```

In the component then we simply need to add it in the instantiation:

```
this.form = this.fb.group({
    name: [''],
    color: ['']
});
```

### Calendar

To add a calendar for date input, we use the `Calendar` component from PrimeNg.
Same as the color picker, we add the calendar for the date by using the `formControlName="validity"`:

```
<div class="p-3">
    <form [formGroup]="form">
        <div class="form-group row">
            <label for="name" class="col-sm-3 col-form-label">Name</label>
            <div class="col-sm-9">
                <input id="name" type="text" class="form-control" formControlName="name" placeholder="Enter name" />
            </div>
        </div>
        <div class="form-group row">
            <label for="color" class="col-sm-3 col-form-label">Color</label>
            <div class="col-sm-9">
                <p-colorPicker formControlName="color"></p-colorPicker>
            </div>
        </div>
        <div class="form-group row">
            <label for="date" class="col-sm-3 col-form-label">Date</label>
            <div class="col-sm-9">
                <p-calendar formControlName="validity" dateFormat="D d, M yy"></p-calendar>
            </div>
        </div>
    </form>
</div>
```

We can also specify a `dateFormat` like here `"D d, M yy"` will display `Wed 13, Sep 2017`. The formats can be found on PrimeNg doc:

```
d - day of month (no leading zero)
dd - day of month (two digit)
o - day of the year (no leading zeros)
oo - day of the year (three digit)
D - day name short
DD - day name long
m - month of year (no leading zero)
mm - month of year (two digit)
M - month name short
MM - month name long
y - year (two digit)
yy - year (four digit)
@ - Unix timestamp (ms since 01/01/1970)
! - Windows ticks (100ns since 01/01/0001)
'...' - literal text
'' - single quote
```

And similarly as the name and color, we need to instantiate it:

```
this.form = this.fb.group({
    name: [''],
    color: [''],
    validity: [new Date()]
});
```

### Range

To add a range input, we use the `Slider` component from PrimeNg.
Range can be added using `p-slider` and also work with `formControlName="range"`.

```
<div class="form-group row">
    <label for="range" class="col-sm-3 col-form-label">Range</label>
    <div class="col-sm-9">
        <p-slider formControlName="range" [range]="true" [min]="0" [max]="1000"></p-slider>
    </div>
</div>
```

In order to specify that the value is a range; a value composed of two values, we specify `[range]="true"`.

```
this.form = this.fb.group({
    name: [''],
    color: [''],
    validity: [new Date()],
    range: [[0, 100]]
}
```

The range being an array of two elements, we can instantiate it with any value here `0 and 100`.

### Choice

Lastly for a choice, we use the `Dropdown` component from PrimeNg.

```
<div class="form-group row">
    <label for="choice" class="col-sm-3 col-form-label">Choice</label>
    <div class="col-sm-9">
         <p-dropdown [options]="choices" formControlName="choice"></p-dropdown>
    </div>
</div>
```

The dropdown also support reactive form notation with `formControlName="choice"`. In order to provide the options, we pass an object `{ label: string; value: any; }`, the label is used to display on the selection and the value is the one saved into the form variable.

```
export class ComplexComponent implements OnInit {
  form: FormGroup;
  choices: {label: string, value: string}[];

  constructor(private fb: FormBuilder) {
  }

  ngOnInit() {
    this.choices = [
      { label: 'test 1', value: 'test-1' },
      { label: 'test 2', value: 'test-2' },
      { label: 'test 3', value: 'test-3' },
      { label: 'test 4', value: 'test-4' }
    ];

    this.form = this.fb.group({
      name: [''],
      color: [''],
      validity: [new Date()],
      range: [[0, 100]],
      choice: [this.choices[0].value]
    });
  }
}
```

Now that we saw how to build common elements, we can move on to build the array sections.

## 2. Building the array sections

Let's start first by looking at the template of a form array:

```
<div class="form-group row">
    <label class="col-sm-3 col-form-label">Sections</label>
    <div class="col-sm-9" formArrayName="sections">
        <div *ngFor="let section of sections.controls; index as i" [formGroupName]="i">
            <input id="{{ 'sectionName-' + i }}" type="text" class="form-control" formControlName="sectionName" placeholder="Enter section name" />
        </div>
    </div>
</div>
```