# DotNet Framework Standard Core and ASPDotNet

A lot of things have changed from the past few years with the DotNet ecosystem. In many occasions, I have seen myself explaning the differences between DotNet Core and DotNet Standard but more precisely the difference between DotNet Framework application, DotNet Standard libraries and how do they all relate to ASP Net Core.
So many variant and buzz words that it is quite confusing to first look at.
So today, I would like to take another approach and dive into each one of them by explaining the differences, not in term of keyword but in term of project template. What is the difference between DotNet Standard library or DotNet Core library, what is the difference between DotNet Core application or DotNet Framework application, etc... This post will contain 6 points:

```
1. DotNet Framework
2. DotNet Standard
3. DotNet Core
4. Which one to choose
5. ASP.Net Core
```

## 1. DotNet framework

Everything started from DotNet framework.
We would build libraries, console app and web application using ASP.Net MVC on top of DotNet Framework 1.x 2.x 3.x 4.x etc...
This remains the most widely used platform.

DotNet framework provides a set of API available for application to use in order to tap into core functionalities provided by the framework like garbage collection but also lower level functionalities like operating system or even hardware.

The problem was that the framework and the operating system, Windows here, used to be highly coupled. They worked hand in hand together to deliver applications. This limited the amount of use cases for DotNet as it was tied to Windows ecosystem.

In the most recent years, surfing the wave of cross platform development, came the abstraction of the underlying core functionalities of DotNet with the goal of decoupling DotNet from the operating system.

DotNet Standard was born.

## 2. DotNet Standard

DotNet Standard standardizes the API previously provided by DotNet Framework.
This allows libraries who previously were dependent on DotNet Framework, hence Windows, to now inverse their dependency and point to DotNet Standard which then decouples them from Windows.

DotNet Standard is meant to be the platform targeted by libraries for maximum compatibility.

But another problem is that not all functionalities of the DotNet Framework can be ported because some can't be abstracted and some just take time. On top of that, new features needed to be added which would be cross platform hence  not targeting DotNet Framework.

There came DotNet Core.

## 3. DotNet Core

DotNet Core can be the platform for libraries, console app and web applications.
DotNet Core is meant for cross platform development. The framework contains all new features ensuring cross platform but is not backward compatible with DotNet Framework.

## 4. Which one to choose

For libraries there is then 3 choices, 

- DotNet Framework libraries, 
- DotNet Standard libraries,
- DotNet Core liraries.

The right framework to target depends on the audience of the library.

If the library is meant to be used by general public, cross platform, cross framework then DotNet Standard should be used as it offers the most compatibility.

If the library is meant to be used by only DotNet Framework libraries or applications then DotNet Standard can be used, if not sufficient then DotNet Framework should be used.

If the library is meant to be used by DotNet Core applications then DotNet Standard can be used and if not sufficient then DotNet Core should be used.

Now that we know the diffences between DotNet Standard, Core and Framework we can choose which suits our needs.

## ASP.Net Core

_ASP.Net Core is a library which targets DotNet Standard_.
This means that _it can be use in both, DotNet core projects and DotNet Framework projects_.

For example, when creating new project and selecting the template it is possible to select DotNet Framework 4.7 with ASP.Net Core:

[Image]()

# Conclusion

I have always been a supporter of the cross platform movement. DotNet Standard together with Core opens a lot of possibilities. In this post we saw what were the differences between the frameworks available and what were the goal of each of them. I hope you enjoyed this post as much as I enjoyed writing it. See you next time!