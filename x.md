# Implement a registration process with email verification and JWT token for WebSharper sitelet

Last week we saw how we could implement a simple JWT authentification by implementing a token and a refresh endpoinds on our API to deliver the respective tokens.
Today I will show how to implement a registration process with email verification used in a WebSharper sitelet.
 
 _This post will not contain the email submission service part._

This post will be composed by 4 parts:

```
 1. Overview
 2. JWT tokens
 3. Auth endpoints
 4. Site endpoints
```

## 1. Overview

There are multiple paths involved in the registration with email verification. 
The first obvious one is the registration form submission. Once submitted, the server constructs a special `activate token` which only purpose is to authorize the activation of the account, constructs an email containing the link to activate the account with the token and submits it to the email given from the form and finally construct a second `send activation email token` which only purpose is to authorize the activation email to be sent again to the user. 
When the client receives the `send activation email token`, it can then show a success page with a link to resend the email if somehow the user has not received it.
Then from the email, the user can click on the link which will redirect to the client page which automatically submit the `activate token` to the server where the server can then activate the account and in turn return the `access token` for the user to log in.

That's the successful path, but in the case of the user not receiving the email, we also need to provide a way for the user to get back to the page where the email can be resent.
In order to do that, we will modifiy the `/token` endpoint to submit the `send activation email token` when the user tries to log in with an account not activated.
The client will receive the token and will know the context - `user is not activated` - and can show the page with a message stating that the registration was completed but the account need verification and the page contains a link to resend the email.

Another potential issue is that the `activation token` can expire. We do not want to let a valid token stay valid for a long period, in case the user emails are compromised, we do not want to leave a chance for impersonation.
So if the activation fail, the server will return an error which will indicate to the client the context - `activation token failed, re-log in and resend activation email`. This will force the user with an expired activation token to re-log in to access the page described above containing the link to resend a fresh activation email.

Those are the main scenarios which we will cover in this post. Let's start by talking about the different JWT tokens involved.

## 2. JWT tokens

In my previous post (link), I talked about what JWT tokens were and mentioned the member `TokenRole` which defines the role of the particular token.
It is very useful to restrict the validity of the token to certain part/endpoints on the server. From the previous post, we have already two roles `access_token` and `refresh_token` where `access_token` gives access to resources accross all endpoints and `refresh_token` allows to get a new fresh pair of tokens.

Here we introduce two new roles `activate_token` and `send_activation_email_token`.

`activate_token` will only allow to __activate the user contained in the subject in the token payload__.
`send_activation_email_token` will only __allow to send the activation email to the subject contained in the token payload__.

__Why do we need different tokens?__

We need different tokens to ensure that each tokens provided has an extremely limited perimiter of action.
The user account not being verified, we need to assume that the user is an untrusted resource therefore we need to take precautions.

## 3. Auth endpoints

From the overview, we can extract 4 endpoints needed for the web api:

```
 1. /auth/token
 2. /auth/register
 3. /auth/sendactivationemail
 4. /auth/activate
```

## 4. Site endpoints

From the overview, we can extract 4 endpoints needed for the webapp:

```
 1. /register
 2. /register/success/[send_activation_email_token]
 3. /register/activate/[activation_token]
 4. /register/activate/fail/[send_activation_email_token]
```

# Conclusion
