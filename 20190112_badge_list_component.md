# Create a mobile friendly badge list in Angular with PrimeNG and Bootstrap

A badge list is common component on a website allowing to display a list of items, usually one word items. Those badges can be clickable which can then be used for filtering or even navigation. When a screen space is available, those badges can be simply displayed inlined but when screen space is reduced, mobile screens are a good example, having a list of badges can potentially take up 30% of the screen. Today we will see how we can free up screen space, we need to move the badge list into a mobile friendly component in three steps:

1. Bootstrap display directive
2. PrimeNG side panel
3. Repsonse badge list 

![demo](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20190112_badge_list_component/badge-list-component.gif)

## 1. Bootstrap display directive

## 2. PrimeNG side panel

## 3. Repsonse badge list 

```
<div class="container py-2">
  <div class="d-none d-md-block">
    <button pButton type="button" 
      [label]="badge.name" 
      class="ui-button-rounded mb-2" 
      [ngClass]="{ 'mr-2': !last, 'ui-button-primary': badge.selected, 'ui-button-secondary': !badge.selected }" 
      (click)="select(badge)"
      *ngFor="let badge of badges; last as last"></button>
  </div>

  <div class="d-md-none text-center">
    <button pButton type="button" 
      label="Brands" 
      icon="pi pi-sort" 
      iconPos="right" 
      class="ui-button-secondary" 
      (click)="display = true" 
      [ngStyle]="{ 'width': '7em'}"></button>
  </div>
  
  <p-sidebar [(visible)]="display" position="bottom" appendTo="body" styleClass="ui-sidebar-md">
    <div>
      <h3 class="mb-3">Brands</h3>
      <button pButton type="button" 
        [label]="badge.name" 
        class="ui-button-rounded mb-2" 
        [ngClass]="{ 'mr-2': !last, 'ui-button-primary': badge.selected, 'ui-button-secondary': !badge.selected }" 
        (click)="select(badge)"
        *ngFor="let badge of badges; last as last"></button>
    </div>
  </p-sidebar>
</div>
```

```
import { Component } from '@angular/core';

@Component({
  templateUrl: './badge-list.component.html'
})
export class BadgeListComponent {
  badges: {
    name: string;
    selected: boolean;
  }[];

  constructor() {
    this.badges = [
      {
        name: 'Airbus',
        selected: false
      },
      {
        name: 'Verizon',
        selected: true
      },
      {
        name: 'Lufthansa',
        selected: false
      },
      {
        name: 'Forever',
        selected: false
      },
      {
        name: 'Bootstrap',
        selected: false
      },
      {
        name: 'Original',
        selected: false
      },
      {
        name: 'Crunch',
        selected: false
      },
      {
        name: 'Bubble',
        selected: false
      },
      {
        name: 'Architects',
        selected: false
      },
      {
        name: 'Dollars',
        selected: false
      },
      {
        name: 'Cereals',
        selected: false
      },
      {
        name: 'FirstRate',
        selected: false
      },
      {
        name: 'Authentic',
        selected: false
      }
    ]
  }

  select(badge) {
    this.badges = this.badges.map(b => 
      Object.assign({}, b, { selected: b.name == badge.name ? true : false })
    );
  }
}
```

```
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations'
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

import { ButtonModule } from 'primeng/button';
import { SidebarModule } from 'primeng/sidebar';

import { AppComponent } from './app.component';
import { BadgeListComponent } from './badge-list.component';

const appRoutes: Routes = [
  {
    path: '',
    children: [{
      path: '',
      component: BadgeListComponent
    }]
  }
];

@NgModule({
  declarations: [
    AppComponent,
    ProgressBarComponent,
    NavComponent,
    ContentComponent,
    BadgeListComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    ButtonModule,
    SidebarModule,

    RouterModule.forRoot(
      appRoutes,
      { enableTracing: false }
    )
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
```