# Inline form Angular and PrimeNg

Inline form are used to edit portion of long forms. This makes the process of editing a long form less tedious and less error prone as the focus is on a small portion.
The process of allowing the fields to be editable can be hard as the state of the field currently selected for editing needs to be tracked and the right input fields must be shown.
Angular offers convenient directives to handle showing and hiding elements, together with ngrx store to handle the state and PrimeNg UI components, it is an ideal solution to build inline forms.

```
 1. Build a simple form
 2. 
```

## 1. Build a simple form

For the form we will be using Bootstrap and PrimeNg.
Bootstrap provides universally known css classes.
PrimeNg provides components for Angular like button, accordions, panels or datatables. In this example we will be using it to use a button with icon.

In this example we will build a form containing the following fields:
 
 - Firstname
 - Lastname
 - Address
 - Postal code
 - Home number
 - Mobile number

 ![form]()