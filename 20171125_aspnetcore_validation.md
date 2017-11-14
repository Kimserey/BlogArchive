# Validation in ASP NET Core

In order to ensure that values passed to our web server are correct, it is required to ensure validation. Today we will see how we can implement validation in ASP NET Core using data annotation. This post will be composed by 2 parts:

```
1. Validation with ASP NET Core
2. Show errors from Angular TypeScript frontend
```

## 1. Validation with ASP NET Core

In ASP NET Core, validation can be implemented using data annotation. On each call, parameters are tested against the annotation and the `ModelState` property is filled up.
When any of the parameters is invalid, the model state will be invalid and the following `Model.IsValid` will be `false`.

```
public class BankAccount
{
    public Guid Key { get; set; }
    [Required]
    public string Customer { get; set; }
    [Required]
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
[HttpPatch("{categoryKey}")]
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

## 2. Show errors from Angular TypeScript frontend