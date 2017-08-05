# Inline form Angular and PrimeNg

Inline form are used to edit portion of long forms. This makes the process of editing a long form less tedious and less error prone as the focus is on a small portion.
The process of allowing the fields to be editable can be hard as the state of the field currently selected for editing needs to be tracked and the right input fields must be shown.
Angular offers convenient directives to handle showing and hiding elements, together with ngrx store to handle the state and PrimeNg UI components, it is an ideal solution to build inline forms. In this post we will see how to build a user friendly form in 3 steps:

```
 1. Build a diplay of segmented forms data
 2. Build the segmented forms
 3. Bind the display edit buttons to the forms displays
```

## 1. Build a diplay of segmented forms data

For the form we will be using Bootstrap, PrimeNg and FontAwesome.
Bootstrap provides universally known css classes. PrimeNg provides components for Angular like button, accordions, panels or datatables. In this example we will be using it to use a button with icon. FontAwesome is a dependency of PrimeNg used for icons.

In most cases, we have a group of properties constituting an object. Let's take for exampple a `User profile` which contains the following properties:

 - Firstname
 - Lastname
 - Address
 - Postal code
 - Home number
 - Mobile number

In order to provide the best user experience for our users, we will implement an inline form. We start first by defining groups of properties which make sense to be changed together, for example firstname/lastname would be together, address/postal code would be together and finally the numbers would be together.
We then build the form and add a clear separation between the groups with `<hr/>`. 
The separation also allow us to add a floating right edit button beside each section without making the display too cluttered.

```
<button pButton type="button" icon="fa-pencil" class="ui-button-secondary" (click)="toggleEdit('name')"></button>
```

We end up with the following html:

```
<p-panel header="Profile">
    <div class="row mb-3">
        <div class="col-sm-3"><strong>Firstname</strong></div>
        <div class="col-sm-7">{{ profile.firstname }}</div>
        <div class="col-sm-2 text-right">
            <button pButton type="button" icon="fa-pencil" class="ui-button-secondary" (click)="toggleEdit('name')"></button>
        </div>
    </div>
    <div class="row mb-3">
        <div class="col-sm-3"><strong>Lastname</strong></div>
        <div class="col-sm-9">{{ profile.lastname }}</div>
    </div>
    <hr/>

    <div class="row mb-3">
        <div class="col-sm-3"><strong>Address</strong></div>
        <div class="col-sm-7">{{ profile.address }}</div>
        <div class="col-sm-2 text-right">
            <button pButton type="button" icon="fa-pencil" class="ui-button-secondary" (click)="toggleEdit('address')"></button>
        </div>
    </div>
    <div class="row mb-3">
        <div class="col-sm-3"><strong>Postal code</strong></div>
        <div class="col-sm-9">{{ profile.postalcode }}</div>
    </div>
    <hr/>

    <div class="row mb-3">
        <div class="col-sm-3"><strong>Home number</strong></div>
        <div class="col-sm-7">{{ profile.homeNumber }}</div>
        <div class="col-sm-2 text-right">
            <button pButton type="button" icon="fa-pencil" class="ui-button-secondary" (click)="toggleEdit('number')"></button>
        </div>
    </div>
    <div class="row mb-3">
        <div class="col-sm-3"><strong>Mobile number</strong></div>
        <div class="col-sm-9">{{ profile.mobileNumber }}</div>
    </div>
</p-panel>
```

 ![form](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20170810_form_ng_prime/form.PNG)

We have the data displayed and have the edit buttons but those don't do anything yet.
Next we will be building the individual forms for each group of fields.

## 2. Build the segmented forms
