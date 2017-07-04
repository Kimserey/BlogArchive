# Managing global state with Ngrx store in Angular

The goal of components in Angular is for them to be completely independent. This can lead to mismatch of displayed data where one component isn't in sync with what other components are displaying. One solution is to have a stateful service shared among all components and delivering global data. This is alright when a limited number of components need to share data but when multiple pieces have to be globally accessible among multiple components, the need for a global state becomes inevitable.
Global state has had a bad reputation since inception due to its unpredictable nature. Redux has emerged as a way to managed this unpredictability by making the state immutable and  operations acting on the state synchronous and stateless functions (a similiar approach can be found in the actor pattern). 
In the past few years the principales of Redux has inspired multiple implementations, one of them being the Ngrx store for Angular.
Today I will go through the library and build a sample application demonstrating how Ngrx store can be used to share a global state and deliver continuous updates. This post will be composed of [] part.

[https://github.com/ngrx/store](https://github.com/ngrx/store)