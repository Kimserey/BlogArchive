# OAuth 2.0, OpenID Connect and Identity Server

When it comes to authentication and authorization, the most used standard is OAuth 2.0 with OpenID Connect.
Few weeks ago I discussed [Resource owner password](https://kimsereyblog.blogspot.sg/2017/04/resourceownerpassword-with-identity.html) and [Implicit](https://kimsereyblog.blogspot.sg/2017/09/implicit-flow-with-identity-server-and.html) flows focusing mainly on implementations with Identity Server. Today I will give more insights on what is OAuth 2.0 and OpenID Connect are and how Identity Server relates to them.

```
1. What is OAuth 2.0
2. What is OpenID Connect
3. What is Identity Server
```

## 1. What is OAuth 2.0

[OAuth 2.0](https://tools.ietf.org/html/rfc6749) is an authorization protocol enabling applications to have a limited access to protected resources. The authentication and authorization is handled in the Identity provider (Idp) who is in charge of delivering a bearer access token to client apppication after having authenticated the resource owner, usually the user.

In a concrete example, I have an application which you are a user from. When you log in, I want to get your profile picture from Facebook to display it on my application. The straight forward approach would be for my application to ask your Facebook username and password and to log into your Facebook......
it directly. But this will cause many problems, the first one being that you would give your credentials to a third party (my application) and you wouldn't know what I will be doing with it. The second problem is that I will have full access to your account, there is no way for you to restrict the access to only the profile picture. Lastly it would be hard to revoke access, the only way would be to change your password. 
This is where OAuth 2.0 comes into picture. 

OAuth 2.0 defines different flows of authorization which cater for different scenarios. The flows are Authorization code, Implicit, Client credentials and Resource owner password flows.

In a nutshell,

 - __Authorization code__ is used for clients who can keep a secret between themselves and the idp like hosted frontend.
 - __Implicit flow__ is used for pure frontend clients like SPA who can't keep a secret.
 - __Client credentials__ is used when the client needs to authenticate as itself, for example when your own application needs access to your own protected resource.
 - __Resource owner password__ is used when the client is trusted. Be very cautious with this flow as the user credentials will need to be given to the client for the client to pass it to the idp.

OAuth 2.0 protocol also defines how clients are registered and how the flows occurs with the exchange on defined HTTP endpoints.

## 2. What is OpenID Connect