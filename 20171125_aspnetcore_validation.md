# Validation in ASP NET Core and Angular

Validation is an important part of the application development. There are two parts where validation is required, the API level and the frontend. The API validation is meant to prevent any malformed input to corrupt our data while the frontend validation is meant to guide the user to fill in a form by providing interactive feedback on her input. ASP NET Core for the backend and Angular for the frontend both ship with validation mechanisms fulfilling are requirements. Today we will see how we can implement validation in ASP NET Core using data annotation and inline validation with Angular reactive form. This post will be composed by 2 parts:

```
1. Implement validation for ASP NET Core
2. Implement inline validation for Angular form
```

## 1. Implement validation for ASP NET Core

In ASP NET Core, validation can be implemented using data annotation. On each call, parameters are tested against the annotation and the `ModelState` property is filled up.
When any of the parameters is invalid, the model state will be invalid and the following `Model.IsValid` will be `false`.

```
public class BankAccount
{
    public Guid Key { get; set; }
    [Required]
    public string Customer { get; set; }
    [Required]
    [RegularExpression("^[0-9]+$")]
    public string Number { get; set; }
}
```

`[Required]` means that the property value is required to be present for the model state to be valid.
 
```
[HttpPost]
[ProducesResponseType(typeof(Guid), 200)]
public async Task<IActionResult> Post([FromBody]BankAccount viewModel)
{
    if (!ModelState.IsValid)
    {
        return BadRequest(ModelState);
    }

    var key = Guid.NewGuid();
    this.service.Save(new BankAccount {
        Key = key,
        Customer = viewModel.Customer,
        Number = viewModel.Number       
    });

    return Ok(key);
}
```

When the model state is invalid, we return a `BadRequest` passing in as argument the model state itself. This will result of an error will be an object composed of the property name with the error linked to it. For example if we don't provide the Customer or Number, we will have the following error:

```
{
    "Customer": [
        "The Customer field is required."
    ],
    "Number": [
        "The Number field is required."
    ]
}
```

It is also possible to validate model created from within the controller function. For example if we are using `JsonPatchDocument<T>`, we can't annotate the patches. Therefore we first apply the patches onto the resource then we map it to a viewModel class containing the annotation. Then we use `TryValidateModel` to validate the viewModel.
Once we use `TryValidateModel`, the errors are registered into the `ModelState` which we can return straight to the UI.

```
[HttpPatch("{bankAccountId}")]
[ProducesResponseType(204)]
public async Task<IActionResult> Patch(Guid bankAccountId, [FromBody]JsonPatchDocument<BankAccount> patches)
{ 
    var bankAccount = this.service.Get(bankAccountId);
    patches.ApplyTo(bankAccount);
    
    if (!TryValidateModel(bankAccount))
    {
        return BadRequest(ModelState);
    }
   
    this.service.Save(bankAccount);
    return NotContent();
}
```

Now that we know how to validate input and return error when any, we will see how we can handle the errors from the front end.

## 2. Implement inline validation for Angular form

The following will demonstrate how to handle errors from Angular form, if you aren't familiar with reactive forms, you can have a look at my previous post on [how reactive forms work in Angular](https://kimsereyblog.blogspot.sg/2017/06/reactive-form-with-angular.html).

The best approach to handle error is to implement inline validation. Knowing the restriction of the API, we can deduce rules which can be directly applied from the frontend. For example, we have two validation here:

 1. for the customer name, it is __required__,
 2. for the bank account number it is __required__ and must fulfill the pattern `^[0-9]+$`.

Knowing this rules, we can apply them directly to our form:

```
@Component({
  selector: 'app-create-bank-account',
  templateUrl: 'create-bank-account.html'
})
export class CreateBankAccountComponent implements OnInit {
  @Output() submitForm = new EventEmitter<{ customer: string, number: string }>();

  form: FormGroup;

  get customer() {
    return this.form.get('customer');
  }
  
  get number() {
    return this.form.get('number');
  }

  constructor(private fb: FormBuilder) { }

  save() {
    this.submitForm.emit(this.form.value);
    this.form.reset();
  }

  cancel() {
    this.form.reset();
  }

  ngOnInit() {
    this.form = this.fb.group({
      customer: ['', Validators.required],
      number: ['', [Validators.required, Validators.pattern(/^[0-9]+$/)]],
    });
  }
}
```

Now on the template, using `Boostrap v4`, we can show and hide errors and indicate to the user which fields are valid or invalid:

```
<form [formGroup]="form">
    <div class="form-group row">
        <label for="customer" class="col-sm-2 col-form-label">
            <strong>Customer name</strong>
        </label>
        <div class="col-sm-10">
            <input id="customer" name="customer" type="text" class="form-control" [ngClass]="{ 'is-invalid': !customer.pristine && !!customer.errors, 'is-valid': !customer.pristine && !customer.errors }" formControlName="customer" placeholder="Customer name" />
            <div class="invalid-feedback" *ngIf="!customer.pristine && customer.errors?.required">Customer name is required</div>
        </div>
    </div>
    <div class="form-group row">
        <label for="number" class="col-sm-2 col-form-label">
            <strong>Number</strong>
        </label>
        <div class="col-sm-10">
            <input id="number" name="number" type="text" class="form-control" [ngClass]="{ 'is-invalid': !number.pristine && !!number.errors, 'is-valid': !number.pristine && !number.errors }" formControlName="number" placeholder="Account number"/>
            <div class="invalid-feedback" *ngIf="!number.pristine && number.errors?.required">Account number is required</div>
            <div class="invalid-feedback" *ngIf="!number.pristine && number.errors?.pattern">Only numeric characters are allowed</div>
        </div>
    </div>
    <button type="button" class="ui-button-info" pButton icon="fa-close" (click)="cancel()" label="Cancel"></button>
    <button type="button" class="ui-button-success" pButton icon="fa-check" [disabled]="!form.valid" (click)="save()" label="Save"></button>
</form>
```

Here we use `ngClass` to display `is-valid` or `is-invalid` depending on whether the form control has errors or not. When pristine, we simply do not set anything.
Next we display the adequate error message based on the error inside the array of errors for the particular control. For example for required customer name, we will have the following condition:

```
!customer.pristine && customer.errors?.required
```

When the control is not pristine and there is the `required` error, it will mean that the value is empty on that input. We will then have the `is-invalid` class on the input which will outline the input in red and have the error message displayed with `invalid-feedback` which display a text in red under the input.

Lastly we set the save button disable to the following: `[disabled]="!form.valid"`. This will grey out the save button when the form values are invalid.

We now have a complete inline validation on the frontend.

# Conclusion

Today we saw how to implement validation on both, backend and frontend. The backend validation is used to prevent any wrongly formatted input to corrupt our data while the frontend validation is used to guide the user to input correctly formatted data. They are both important and both have to be implemented, frontend for the user experience and backend for the data integrity. For the frontend, we saw how to implement validation using reactive form with Angular which provides simple validators and for the backend, we saw how ASP NET Core provides automatic validation based on data annotation. Hope you like this post as much as I like writting it. If you have any question, leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam)! See you next time!