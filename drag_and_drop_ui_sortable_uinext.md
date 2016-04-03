We can see all the available options here. Let s review in order what we are interested in so that we can focus on binding this first.

Group


Name


Pull


Put

This option will define the behaviour of the list by specifying if the elements can be pulled out of the list or whether other can put elements into the list.

We represents pull in the following way

And put




Sort

Specify whether the list can be sorted or not.

OnAdd


OnAdd is triggered when an item is added.

OnSort


OnSort is triggered when the list is sorted. Take note that OnSort is also called when an item is added.

OnAdd and OnSort take callbacks in their definition.


When the callback is called it is passed an event which contains info about the list.

The interesting information are


NewIndex


OldIndex


From


The origin list


To


The destination list


Item


The item added

Now one issue is that JS is case sensitive. Therefore we can't directly use record type with first lettet capital members.


To make a manual binding, we can use NameAttribute.

Example..

And that's it! That is all we need to bring this amazing library to use it with WebSharper in F#.

Today we saw how to bind JS libraries. Also we saw how we could directly use our own record types to pass it to JS functions but we also saw how those record types could be used as well to directly deal with results of JS functions.


Sortable is an amazing library which is easy to configure and allows to build interactive nice webapp. As always if you have any comments please leave it below or hit me on Twitter @Kimserey_Lam. Thanks for reading!
