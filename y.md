# Jwt authentication for WebSharper sitelet

Few weeks ago I talked about how to implement [a Jwt OWIN middleware which can be used to authenticate a WebSharper sitelet](https://kimsereyblog.blogspot.co.uk/2017/01/authentication-for-websharper-sitelet.html).
Today I would like to show another simpler way of protecting a WebSharper sitelet with (again) Jwt tokens, but this time, without the need of implementing a OWIN middleware which is ideal for SPA.
This post will be compose by 3 parts:

```
 1. Overview
 2. Authentication flow
 3. Implementation
```

## 1. Overview

Like our previous post, we will be using the Jwt token to implement a Bearer authentication.

Check out the description in my previous post if you aren't sure how jwt works, [post here](https://kimsereyblog.blogspot.co.uk/2017/01/authentication-for-websharper-sitelet.html).

__Why is it called Bearer?__

The definition of a Bearer is "someone who carries something". In the auth context, the bearer carries the auth token and can provide enough information for authentication to the other party without the need of any external service.

To implement the Bearer auth, we will start by defining a way to create tokens. In order to properly implement the authentication, we will need __two types of token__, __an access token__ and __a refresh token__. We will see the difference later.

Once we have a proper way to create and refresh tokens, we will be in measure to protect our sitelet via a simple function which ensures the endpoints are protected.

Let's start first by understanding the authentication flow.

## 2. Authentication flow

Here's how the authentication scenario works:
 
 1. User POST request to server to `/auth/token` giving credentials
 2. Server validates credentials and generate (and returns) access token and refresh token with user principal embedded in token
 3. Users uses access token to request secured resources from SPA
 4. When access token expires, requests POST `/auth/refresh` giving refresh token
 5. Server validates refresh token and fetch last updated user principal and returns latest user principals in a new set of access token and refresh token

We can see from 4-5 that we will need a refresh token if the access token expires.

__Why do we need a refresh token?__

The refresh token role is to __refresh the access token by creating a new access token with the most up to date user principals__.

In bearer auth, when the user obtains a valid token, __the user has all the rights granted by the token as long as it is valid__. 

So if we need to restrict the user access or even lock the user, the changes will only take effect when the token expires. To prevent that, we need to only issue short living tokens. This way the token will only be valid for short period.

Without refresh token, because the token is only valid for a short time, the user will need to resend credentials every time the access token expires. To remove the need of sending back credentials, we use a refresh token.

The refresh token is a long living token. It's purpose is solely to refresh the access token. 
It is issued together with the access token but __it is only required when the access token expires__ so it is usually kept in a secure location on client side and only sent when access token expires, in contrast to the access token which is sent on all requests needing authentication.

__What about attacks?__

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
