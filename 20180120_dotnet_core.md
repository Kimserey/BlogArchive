# DotNet Framework Standard Core and ASP Net Core

Lot of things have changed from the past few years in the DotNet ecosystem. In many occasions, I have seen people get confused with the differences between DotNet Core, DotNet Standard and DotNet Framework and how do they all relate to ASP Net Core.
I don't blame them, so many new keywords that it is quite confusing to first look at.
Today, I would like to explain the differences in term of project templates. What is the difference between DotNet Standard library or DotNet Core library, what is the difference between DotNet Core application or DotNet Framework application, etc... This post will contain 5 points:

```
1. DotNet Framework
2. DotNet Standard
3. DotNet Core
4. How to choose
5. ASP.Net Core
```

## 1. DotNet Framework

Everything started from DotNet framework.
We would build libraries, console app and web application using ASP.Net MVC on top of DotNet Framework.
DotNet framework provides a set of API available for application to use in order to tap into core functionalities provided by the framework like garbage collection but also lower level functionalities like operating system or even hardware.

The problem was that the framework and the operating system, Windows here, used to be highly coupled. They worked hand in hand together to deliver applications. This limited the amount of use cases for DotNet as it was tied to Windows ecosystem.

In the most recent years came DotNet Standard, the abstraction of the underlying core functionalities of DotNet with the goal of decoupling DotNet from the operating system and therefore allowing cross platform development.

## 2. DotNet Standard

DotNet Standard standardizes the API previously provided by DotNet Framework.
This allows libraries who previously were dependent on DotNet Framework to now inverse their dependency and point to DotNet Standard which then decouples them from Windows.

DotNet Standard is meant to be the platform targeted by libraries for maximum compatibility.

But another problem is that not all functionalities of the DotNet Framework can be ported because some can't be abstracted and some just take time. On top of that, new features needed to be added which would be cross platform hence  not targeting DotNet Framework. This is where DotNet Core comes into picture.

## 3. DotNet Core

DotNet Core can be the platform for libraries, console app and web applications.
DotNet Core is meant for cross platform development. The framework contains all new features ensuring cross platform but is not backward compatible with DotNet Framework.

## 4. How to choose

For libraries there are 3 choices:

- DotNet Framework libraries, 
- DotNet Standard libraries,
- DotNet Core liraries.

The right framework to target depends on the audience of the library.

If the library is meant to be used by general public, cross platform, cross framework then DotNet Standard should be used as it offers the most compatibility.

If the library is meant to be used by only DotNet Framework libraries or applications then DotNet Standard can be used, if not sufficient then DotNet Framework should be used.

If the library is meant to be used by DotNet Core applications then DotNet Standard can be used and if not sufficient then DotNet Core should be used.

Now that we know the diffences between DotNet Standard, Core and Framework we can choose which suits our needs.

## 5. ASP.Net Core

__ASP.Net Core is a library which targets DotNet Standard__.
This means that __it can be use in both, DotNet core projects and DotNet Framework projects__.

For example, when creating new project and selecting the template it is possible to select DotNet Framework 4.7 with ASP.Net Core:

![Image](https://raw.githubusercontent.com/Kimserey/BlogArchive/github/img/20180120/aspnetcore.PNG)

# Conclusion

I have always been a supporter of the cross platform movement. DotNet Standard together with Core opens a lot of possibilities. In this post we saw what were the differences between the frameworks available and what were the goal of each of them. I hope you enjoyed this post as much as I enjoyed writing it. See you next time!