# Authorization in ASP.NET Mvc

Last week I touched on how we could authenticate users using Resource Owner Password flow with identity server. Authentication is the act of taking the information provided and verifying the "identity" of the user, ensuring that Alice (our beloved example user) is who she "claims" to be.
In the program itself, we take her credentials and verify it and create and identity stating that the user is Alice and has claims A, B and C.

Authentication is the first part of the access security, the second part is the authorization. The difference being that for authorization, we know who the user is, what we are verifying is if Alice is allowed to perform what she is trying to perform. The easiest example is the difference between user access and admin access commonly seen in software where users are authenticated but aren't authorized to perform all the actions available in the system.

ASP.NET Mvc comes with a set of useful tools to perform authorization. Today I will give examples on how we can use the different interfaces and services provided to quickly build authorization.
This post will be composed by 4 parts:

1. Setup the test
2. Role-based authorization
3. Claim-based authorization
4. Policy-based authorization
5. Resource-based authorization

## 1. Setup the test

In order to test our authorization we would need a test example.
The quickest way is to have a jwt middleware which automatically authenticate and create an endpoint directly giving a valid token with claims. We start by creating a web api project and add the jwt authorization library:

... Name

Then we add an endpoint for the token
...

Next we simply test by adding the Authorize attribute. You can also check the user on the HttpContext, it should be set to Alice.

## 2. Role-based authorization

Mvc also provides an easy way to add role authorization by passing the role name in the attribute itself.

... Example

Our endpoint will not be accessible for Alice. We need to give her the claim.

...

## 3. Claim-based authorization

A claim is a property of Alice which defines her, who she is in regards to our system.
The most obvious on is that she claims to be Alice. This translates to a claim "sub:alice" for subject.
If she claims to be an admin she will have a claim "roles:admin".

Now we might have more business specific claims like she is part of the finance department therefore she would have the claim "departments:finance".

The jwt token itself is a set of claims.

With claims, what we can do is only allow access to a user with claim A or A and B etc... For example we only allow users with the claim Employee and Finance department to access the endpoint.
In order to do so, we need to configure a policy requiring the claims Employee Finance department.

...

Now we should be able to access the endpoint only if Alice has the claim employee and finance department.

## 4. Policy-based authorization

In claim-based we saw a glimpse of policy. A policy is a requirement (or mutiple requirements) to fulfill.
Role and claim based authorization are constructed on top of policies. What a policy allows us to do is to add multiple requirements for example we could require a role of "roles:user" and some other claims like "country:singapore" and name the claim "SingaporeUsersOnly".

In order to do so we define a policy:

...

Policies also allow more advanced scenario by defining `requirements` and `handlers`.
We can define a policy requirement like so:

```
```

And add a `handler` to be invoked when an endpoint protected by the policy is accessed:

```
```

If the requirement is successful, the authorization will succeed. In contrary if we simply return without succeeding, the next requirement in the pipeline will be invoke. This behavior allows OR logic with requirements.
If for any reason you wish to fail the authorization, it is also possible to call fail and prevent other requirements to succeed.

## 5. Resource-based authorization

The last authorization is resource-based which also make use of policies but, as its name states it, require the resource to perform the authorization.
A typical scenario would be if we need to retrieve a value and check properties against the value before being able to decide whether or not the user has the rights to act on the value.

For example, Alice wants to modify a financial report. She might only be able to modify it if she authored it. Therefore we would need to retrieve the report and check if Alice is the author of it.

We could do that with a if-else within the controller but Mvc provides an `authorizationService` which can be injected in the controller.
This allows us to authorize the request and give in the resource.

Similarly as policies we create a requirement and we create a handler to handle the requirement. The difference this time is that we implement the authorization handler with the resource type.

...

You might be thinking why would we use a if-else on the authorization service when we can use a if-else to directly check the property. The reason is that we can have multiple handlers checking for the same requirement again similar to policies where we want to implement an OR logic where one of the handler can pass the requirement. Another reason is that the logic of the authorization would be in a single place, in the handlers, for the requirements which avoid having the check logic spread in multiple controller endpoints.

# Conclusion

We saw the different type of authorizations available in ASP.NET core mvc and the reason why we should use those. It is important to understand the authorization tools provided by the framework since there isn't one type which can fit all use cases. If you have any question leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Links

- Example source code - []()
- ASP.NET Core Mvc authorization documentation - [https://docs.microsoft.com/en-us/aspnet/core/security/authorization/introduction](https://docs.microsoft.com/en-us/aspnet/core/security/authorization/introduction)
- ASP.NET Core Mvc repository - [https://github.com/aspnet/Mvc](https://github.com/aspnet/Mvc)