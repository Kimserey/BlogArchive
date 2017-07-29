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

## 1. Install PrimeNg

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

## 2. Mold data for Tree structure with reduce

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

  reducePath = (nodes: TreeNode[], path: string) => {
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

    this.files = f.reduce(this.reducePath, []);
  }
}
```

`reducePath` takes the previous state `TreeNode[]`, which is the result of the previous iteration on the previous path value, and the currenct value it is iterating on. The result of the function is the next state. The second argument of `reduce` is the initial value of the state.

__Notice that reducePath is defined as a variable, this is needed in order to recursively call itself.__

__The idea:__

As a tree traversal algorithm, we will be:
 - taking each path one by one,
 - dissecting the path by '/'

After that only three possibilities remain:
 1. if a file => add it as a node
 2. if a non existing folder => add the new folder as a node and recursively reduce the rest of the path
 3. if existing folder => recursively reduce 

### 2.1 If a file => add it as a node

We start first by handling the first scenario, the path is just a file.
If it is just a file, it means that where we reduced to is the correct folder where the file should be. 
So we add it to the list of nodes.

```
  reducePath = (nodes: TreeNode[], path: string) => {
    const split = path.split('/');

    // 2.1
    if (split.length === 1) {
      return [
        ...nodes,
        {
          label: split[0],
          icon: 'fa-file-o'
        }
      ];
    }

    // will be removed
    return [];
  }
```

### 2.2 If a non existing folder => add the new folder as a node and recursively reduce the rest of the path

If the first piece of the path is a folder, it means that we are still reducing the path.
We handle the scenario where the folder does not exist by adding a new folder to the list of nodes.

We know from here that the file will be a child of this newly created folder therefore we reduce the remaining path and set the result to the folder children.

```
reducePath = (nodes: TreeNode[], path: string) => {
    const split = path.split('/');

    // 2.1
    if (split.length === 1) {
      return [
        ...nodes,
        {
          label: split[0],
          icon: 'fa-file-o'
        }
      ];
    }

    // 2.2
    if (nodes.findIndex(n => n.label === split[0]) === -1) {
      return [
        ...nodes,
        {
          label: split[0],
          icon: 'fa-folder',
          children: this.reducePath([], split.slice(1).join('/'))
        }
      ];
    }

    // will be removed
    return [];
  }
```

### 2.3 If existing folder => recursively reduce 

Lastly if the folder already exists, we know that the file will be under an existing folder already within the `nodes`.
So we iterate over all `nodes` and when found, reduce the rest of the path together with the current children of the node.

```
reducePath = (nodes: TreeNode[], path: string) => {
    const split = path.split('/');

    // 2.1
    if (split.length === 1) {
        return [
            ...nodes,
            {
                label: split[0],
                icon: 'fa-file-o'
            }
        ];
    }

    // 2.2
    if (nodes.findIndex(n => n.label === split[0]) === -1) {
        return [
            ...nodes,
            {
                label: split[0],
                icon: 'fa-folder',
                children: this.reducePath([], split.slice(1).join('/'))
            }
        ];
    }

    // 2.3
    return nodes.map(n => {
        if (n.label !== split[0]) {
            return n;
        }

        return Object.assign({}, n, {
            children: this.reducePath(n.children, split.slice(1).join('/'))
        });
    });
}
```

And that's it, this should construct the tree with folders, subfolders and files.

## 3. Other use cases

The tree construct was actually only a demonstration of the utility of the reduce function.