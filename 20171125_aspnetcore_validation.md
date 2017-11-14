# Validation in ASP NET Core

In order to ensure that values passed to our web server are correct, it is required to ensure validation. Today we will see how we can implement validation in ASP NET Core using data annotation. This post will be composed by 3 parts:


1. Validation
2. Returning errors
3. Show errors from TypeScript frontend


## 1. Validation

In ASP NET Core, validation can be implemented using data annotation. On each call, parameters are tested against the annotation and the `ModelState` property is filled up.
When any of the parameters is invalid, the model state will be invalid and the following `Model.IsValid` will be `false`.


## 2. Returning errors

## 3. Show errors from TypeScript frontend