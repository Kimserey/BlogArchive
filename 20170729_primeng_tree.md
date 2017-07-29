# Tree structure in Angular with PrimeNg

PrimeNg is a Angular component library. Compared to other component libraries like ngbootstrap or material, PrimeNg comes with more advance components which can't be found elsewhere, one of them being the tree structure.
Having the component is one thing but having to build the tree data which can be used by the component is another hard part.
Therefore today I will firstly show how we can use PrimeNg and secondly I will show how we can mold data to fit in the model used to build PrimeNg tree.
This post will be composed by 3 parts:

```
1. Install PrimeNg
2. Mold data for Tree structure with reduce
3. Other use cases 
```

# 1. Install PrimeNg

[PrimeNg](https://www.primefaces.org/primeng) can be added via npm `npm install primeng --save`.
It also needs font awesome for icons which can be added via npm `npm install font-awesome --save`.

After installed, under the `/primeng/resources` folder, we should be able to see the style files. Those needs to be added to the styles in the angularCLI `.angular-cli.json` config. 

```
"styles": [
  "../node_modules/font-awesome/css/font-awesome.min.css",
  "../node_modules/primeng/resources/primeng.min.css",
  "../node_modules/primeng/resources/themes/omega/theme.css"
]
```

Each component is contained in its own module. In this tutorial we will be using the `TreeModule` and the `Tree` class.

We start first by importing the module.

```
import { TreeModule } from 'primeng/primeng';

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    TreeModule
  ],
  declarations: [
    PrimeNgComponent
  ]
})
```

A tree is constructed using an array of `TreeNode`. The selector for the tree is `p-tree`. Let's start by making an example tree.

```
import { Component, OnInit } from '@angular/core';
import { TreeNode } from 'primeng/primeng';

@Component({
  template: '<p-tree [value]="files"></p-tree>'
})
export class PrimeNgComponent implements OnInit {
  files: TreeNode[];

  ngOnInit() {
    this.files = [
      {
        label: 'Folder 1',
        collapsedIcon: 'fa-folder',
        expandedIcon: 'fa-folder-open',
        children: [
          {
            label: 'Folder 2',
            collapsedIcon: 'fa-folder',
            expandedIcon: 'fa-folder-open',
            children: [
              {
                label: 'File 2',
                icon: 'fa-file-o'
              }
            ]
          },
          {
            label: 'Folder 2',
            collapsedIcon: 'fa-folder',
            expandedIcon: 'fa-folder-open'
          },
          {
            label: 'File 1',
            icon: 'fa-file-o'
          }
        ]
      }
    ];
  }
}
```

As mentioned previously, we use the `p-tree` selector `<p-tree [value]="files"></p-tree>`. `TreeNode` has a list of field which can be found on the documentation [https://www.primefaces.org/primeng/#/tree](https://www.primefaces.org/primeng/#/tree). All the fields are optional, here we chose the following:

 - label: the label to be printed
 - collapsedIon: the icon displayed when the TreeNode is collapsed
 - expandedIcon: the icon displayed when the TreeNode is expanded, revealing its children
 - children: children TreeNodes of the current TreeNode
 - icon: the icon to be display regardless of any state

The result should be as followed:

![tree](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20170729/tree.PNG)

#  2. Mold data for Tree structure

Tree structures are hard to construct. Especially for file paths, usually what we get is an array of path as followed:

```
[
    'folderA/file1.txt',
    'folderA/file1.txt',
    'folderA/folderB/file1.txt',
    'folderA/folderB/file2.txt',
    'folderC/file1.txt'
]
```

In this section we will be using `reduce` too construct the file tree using an array of path [https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce).

`reduce` iterates over every element of the array while constructing a result passed from iterations to interations.

The benefit of it is that we end up with a code which is free from side effect, employing function only needing input and output.

We start fist by writing the skeleton:

```
export class PrimeNgComponent implements OnInit {
  files: TreeNode[];

  reduce(nodes: TreeNode[], path: string) {
    return [];
  }

  ngOnInit() {
    const f = [
      'folderA/file1.txt',
      'folderA/file1.txt',
      'folderA/folderB/file1.txt',
      'folderA/folderB/file2.txt',
      'folderC/file1.txt'
    ];

    this.files = f.reduce(this.reduce, []);
  }
}
```

`reduce` takes a function taking the previous state `TreeNode[]`, which is the result of the previous iteration on the previous path value, and the currenct value it is iterating on. The result of the function is the next state. The second argument of `reduce` is the initial value of the state.

