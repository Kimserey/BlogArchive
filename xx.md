# Use JS local storage with ListModel with WebSharper UI.Next in F#

Last week I wanted to use the browser local storage to store a list of element. I wanted to update the [resource split project](https://github.com/Kimserey/ResourcesSplit) to have the data stored (temporarily) so that it will be easier to add or remove resources. The browser local storage is ideal for this kind of scenario. Turns out `WebSharper.UI.Next` has the feature built in to persist ListModel so today I will explain how to do it.

This post is composed by two parts:
```
 1. Use local storage with ListModel UI.Next
 2. Debug values stored in Chrome
```

## 1. Use local storage with ListModel in UI.Next

I started to browse WebSharper code and found that `ListModel` exposed a function named `CreateWithStorage` and that the default implementation was set to be used with local storage (ha! exactly what I wanted). The definition can be found [here](https://github.com/intellifactory/websharper.ui.next/blob/master/WebSharper.UI.Next/Models.fsi#L233).

So to use the storage we must use `CreateWithStorage` and `Storage.default`.

```
CreateWithStorage<'Key, 'T when 'Key : equality> : ('T -> 'Key) -> Storage<'T> -> ListModel<'Key,'T>

module Serializer =
    val Default : Serializer<'T>
    
LocalStorage : string -> Serializer<'T> -> Storage<'T>
```

```
let resources = ListModel.CreateWithStorage (fun r-> r.Name) (LocalStorage "local-storage" (Serializer.Default<Resource>))
```

The `id` is the key used to save in the local storage. Now for anything added and removed and anything changed from the ListModel, it will be saved in local storage. And then when we close the browser and open again the page from a fresh page, the list model will load the data from the local storage. The data will be persisted.

## 2. Debug storage in Chrome

The values are stored in local storage. It is possible to see the values from Chrome by accessing the developer console and looking into the storage.

Here you should be able to see your data stored in json format. It is stored as WebSharper stores it.

# Conclusion

Today we saw how we could use ListModel together with local storage and persists the result in local storage. This can be useful for cache or temporary storage. Hope you liked this post! If you have any comments leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!
