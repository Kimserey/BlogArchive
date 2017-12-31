# Implement PATCH on ASP NET Core with JSON Patch

When building web APIs, most of the HTTP methods are implemented, GET, POST, PUT, PATCH and DELETE. While GET, POST and PUT are easily implemented, PATCH functionality is slightly different as it allows to change one or more properties of the resource. It is used to _patch_ the resource. One way to do it is to use a protocol called __JSON Patch__. Today we will see how we can use JSON Patch through the ASP NET Core implementation and how we can construct the request from the frontend. This post will be composed by 3 parts:

```
1. JSON Patch protocol
2. Implementation on ASP NET Core
3. Usage from frontend in TypeScript
```

## 1. JSON Patch protocol

[JSON Patch](https://tools.ietf.org/html/rfc6902)
 is a protocol defining a format expressing operations to be applied on JSON objects.

The operations are composed by the following object:

```
{ op: '', path: '', value: '' }
```

`op` being the operation, `path` being the path of the property of the JSON object and lastly `value` being the value to set the property.

The common ways to patch an object would be to:

 - replace a property
 - delete a property
 - add an item on a property which is a list
 - remove an item from a property which is a list
 - switch positions of two items within a property which is a list
 
Let's see how those operation can be created:

For replacing a property, this can be done with `op: replace`:

```
{ op: "replace",
  path: "/name",
  value: "Kim" }
```

For removing a property, this can be done with `op: remove`:

```
{ op: "remove",
  path: "/name" }
```

For adding a value on a list, it can be done with `op: add` and a path ending with `/-`: 

```
{ 
  op = "add",
  path = "/members/-",
  value = { 
      name: 'Kim'
  } 
}
```

For adding at a particular index, it can be done by specifying the index:

```
{ op = "add",
  path = "/members/0",
  value = new { ... } }
```

To remove at a particular index, it can be done with `remove`:

```
{ op = "remove",
  path = "/members/0" }
```

To set a value at a particular index, it can be done with `replace`:

```
{ op = "replace",
  path = "/members/0",
  value = new { ... } }
```

Lastly to switch positions, it can be done with `move` using the `from` property:

```
{ op = "move",
  from = "/members/2",
  path = "/members/0" }
```

Now that we know how to construct the operation in JSON format, let's see how we can handle those from ASP NET Core.

## 2. Implementation on ASP NET Core

ASP NET Core comes with a built in support for JSON Patch.
All we need to do is to use the `JsonPatchDocument<TResource>` interface which we take as argument of our controller endpoint:

```
public class BankAccountsController : Controller
{
    [HttpPatch("{bankAccountId}")]
    public async Task<IActionResult> Patch(Guid bankAccountId, [FromBody]JsonPatchDocument<BankAccount> patches)
    { ... }
}
```

We can now submit the following request:

```
PATCH /bankAccounts/123

Body:
    [
        {
            "op": "replace",
            "path": "/number",
            "value": "123-123-123"
        }
    ]
```

To use the patches, all we need to do is to apply them by calling th `.ApplyTo(T)` function:

```
public async Task<IActionResult> Patch(Guid bankAccountId, [FromBody]JsonPatchDocument<BankAccount> patches)
{ 
    var bankAccount = this.service.Get(bankAccountId);
    patches.ApplyTo(bankAccount);
   
    this.service.Save(bankAccount);
    return NotContent();
}
```

We start by getting the account from a service and then applying the patches to it. Once applied, the resulting account is modified following the operations provided by the patches. We can simply save it back after. Just by using the `JsonPatchDocument`, we can allow patching of any property of the bank account. 
If in the future we add more properties, those will be made available to be patched without any code change required.

## 3. Usage from frontend in TypeScript

We have the API endpoint. Now what we need is a way to apply those patches submitted to an object on the client-side.
To do that, we can use the `fast-json-patch` library. We can install it using npm:

```
npm install fast-json-patch --save
```

After building the patches, we can apply them using `applyPatch`:

```
import * as jsonPatch from 'fast-json-patch/lib/core';

... some other code

const newBankAccount = jsonPatch.applyPatch(
    bankAccount, 
    <jsonPatch.Operation[]>patches).newDocument;
```

This can be used after submitting patches to the API, updating the model on the client-side for SPA.

# Conclusion

Today we saw how to implement PATCH for web APIs with JSON Patch. We saw how it can be handled in ASP NET Core with `JsonPatchDocument` and how a client-side can use JSON Patch to update its models with `fast-json-patch`. PATCH considerably simplify frontend development for editing as it allows partial update of information which allows a big object to be broken down in multiple update form from the UI yielding smaller patches. Hope you like this post, if you have any question leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!