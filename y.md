# Jwt authentication for WebSharper sitelet

Few weeks ago I talked about how to implement a Jwt OWIN middleware which can be used to authenticate a WebSharper sitelet (link).
Today I would like to show another simpler way of protecting a WebSharper sitelet with (again) Jwt tokens without the need of implementing a OWIN middleware which is ideal for SPA.
This post will be compose by 3 parts:

```
 1. Overview
 2. Authentication flow
 3. Implementation
```

## 1. Overview

Like our previous post, we will be using the Jwt token to implement a Bearer authentication.

Check out the description in my previous post if you aren't sure how jwt works. (link)

Why is it called Bearer?
The definition of a Bearer is "someone who carries something". In the auth context, the bearer carries the auth token and can provide enough information for authentication to the other party without the need of any external service.

So next we will define a way to create tokens. There will be two type of token, an access token and a refresh token. We will see the difference later.

We will also create a function which ensure that the calls on the sitelet endpoints are authenticated and return proper results if not.

Let's start first by understanding the authentication flow.

## 2. Authentication flow

User request to /token giving credentials
Server validates credentials and generate access token and refresh token.
Users uses access token to request secured resources.
When access token expires, requests /refresh giving refresh token.
Server validates that refresh token is valid, find last updated user principal and returns latest user principals in a new set of access token and refresh token.

Why do we need a refresh token?

The refresh token role is to __refresh the access token by creating a new access token with the most up to date user principals__.

In bearer auth, when the user obtains a valid token, __the user has all the rights granted by the token as long as it is valid__. 

So if we need to restrict the user access or even lock the user, the changes will only take effect when the token expires. To prevent that, we need to only issue short living tokens. This way the token will only be valid for like a day for example. 

Now because the token is only valid for a short time, the user will need to resend credentials frequently which is cumbersome. That's where the refresh token comes into play.

The refresh token is a long living token. It's purpose is solely to refresh the access token. 
It is issued together with the access token but is only required when the access token expires so it is usually kept in a secure location on client side and sent when access token expires.

What about attacks?

Using this two tokens allows us to mitigate attacks. Access token is sent on every requests therefore the chance of it getting intercepted is the highest. But because it is only valid during a short period, it gives us more security by only leaving a small room for attacks. 
For the refresh token, because it is only sent when the access token has expired and not all the time, it also lessen the chance of it getting intercepted.

Now that we know the flow, let's see how we can implement it.

3. Implementation

First let's create a simple sitelet with an endpoint.

Code

We have a data endpoint which needs to be secured.
We have the token endpoint to request for the tokens and a refresh endpoint to refresh it.

We can take the implementation of Jwt which we did last post (link). I am just going to copy paste it for convenience.

Code

Now when someone request for token we issue a token after verifying credentials against our stored credentials. In my previous post I talked about how we can store user credentials in a secure way (link).

Code

Next we create a function to authenticate calls, we also create a new ApiContext which will contain the user principals together with the sitelet context.

Code

The function takes a configuration record which will have the jwt configs like token lifespans and private key and takes a token which will be the Bearer token given in the request header.
Note that there are multiple paths in which the token validation will fail, we need to handle every possible scenarios.

Now when the token expires, a request to the refresh endpoint will be issued.

Code

Here we first validate the token and then get the last updated user principal. If the user hasn't been locked, we construct the new set of tokens and return it.

And that's it! Using our authenticate function we can authenticate each desired endpoints of the sitelet. With the access token and refresh token we can have a secured API which can be queried from an SPA or a mobile app.

# Conclusion

Today we saw how we could simply create a Jwt authentication and authenticate the endpoint of our WebSharper sitelet Web API. We saw the difference between an access token and a refresh token and in which scenario they are used. As usual if you have any question leave it here or hit me on Twitter [@Kimserey_Lam](). See you next time!

# Other posts you will like!
