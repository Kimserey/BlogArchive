# Prime NG data table for Angular

In every web application there is a need to display data in a tabular form. If the amount of data is small, a simple combination of HTML with Bootstrap is enough. But when the data is large, or more advanced functionalities are needed like sort or pagination, a more elaborated table needs to be used. If you followed me, you must have noticed that I am a huge fan of Prime NG and once again, Prime NG saves us the burden of implementing a complex data table by providing an Angular component fully featured. Today we will see how to use it in 3 parts:

```
1. Use Prime NG data table
2. Customized cell template
3. Pagination
```

## 1. Use Prime NG data table
### 1.1 Basic usage

Start by installing Prime NG.

```
npm install primeng --save
```

Then in your main app module, register the `DataTableModule` to get access to its components.

```
@NgModule({
  imports: [
    ... other imports
    DataTableModule
  ],
  ... other configurations
})
```

Now that we have imported the module from Prime NG, we can use the data table component and display a list of transactions.

```
import { Component, OnInit } from '@angular/core';

@Component({
  template: `
    <p-dataTable [value]="transactions">
      <p-column field="date" header="Date"></p-column>
      <p-column field="label" header="Label"></p-column>
      <p-column field="amount" header="Amount"></p-column>
    </p-dataTable>
  `
})
export class DataTableComponent implements OnInit {
  transactions: {
    date: Date,
    label: string,
    amount: number
  }[];

  ngOnInit() {
    this.transactions = [
      {
        date: new Date(2017, 10, 10, 13, 10, 15),
        label: 'Third transaction',
        amount: 130
      },
      {
        date: new Date(2017, 7, 3, 9, 35, 0),
        label: 'Second transaction',
        amount: 130
      },
      {
        date: new Date(2017, 3, 27, 15, 43, 10),
        label: 'First transaction',
        amount: 130
      }
    ];
  }
}

```

Each `p-column` directives specify the field to show on the table and the header of the column.

```
<p-column field="date" header="Date"></p-column>
```

![data table]()

As we see here, displaying data is made extremely easy. But what if we need more features like sorting and filtering?

### 1.2 Sort

In order to provide sorting, all we need to do is define which column is sortable by using the `sortable` input:

```
<p-column field="date" header="Date" [sortable]="true"></p-column>
```

Doing that on all columns will make the whole table sortable:

![sortable]()

The column on which the sort is applied can be also set directly on the data table using `sortField` and the order can bbe set using `sortOrder`.

```
<p-dataTable [value]="transactions" [sortField]="sortField" [sortOrder]="sortOrder">
    <p-column field="date" header="Date"></p-column>
    <p-column field="label" header="Label"></p-column>
    <p-column field="amount" header="Amount"></p-column>
</p-dataTable>
```

This allows us to play around in the component by allowing the `sortField` to be set from a function or a button click handler.

### 1.3 Filter

In order to provide filtering, all w eneed to do is to add `filter` on a column:

```
<p-column field="date" header="Date" [filter]="true" [sortable]="true"></p-column>
```

The default filtering is a text filtering. It is also possible to define custom filters which we will see next.

## 2. Customized cell template

