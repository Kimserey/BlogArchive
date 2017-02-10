# Fix 'The method or operation is not implemented Visual Studio' when referencing project in F# solution

Yesterday I had an error prompting me the following error when trying to reference a project within my solution.

![image](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20170210_vs_not_implemented/1.png)

The problem was that I was referencing another project which was unloaded.
When expanding the list of references, there is a warning sign for problematic references:

![image](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20170210_vs_not_implemented/2.png)

Most of the time, for me at least, it indicates a mismatch of F# version between the two libraries.
But a mismatch of F# version doesn't cause the not implemented exception on Visual Studio.
The issue was that the library referenced was __unloaded__.

![image](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20170210_vs_not_implemented/3.png)

__Once I made sure it was loaded, the sign disappeared and VS allowed me to add a reference.__
