# OAuth 2.0, OpenID Connect and Identity Server

When it comes to authentication and authorization, the most used standard is OAuth 2.0 with OpenID Connect (OIDC).
Few weeks ago I discussed [Resource owner password](https://kimsereyblog.blogspot.sg/2017/04/resourceownerpassword-with-identity.html) and [Implicit](https://kimsereyblog.blogspot.sg/2017/09/implicit-flow-with-identity-server-and.html) flows focusing mainly on implementations with Identity Server. There is a lot of confusion revolving around OAuth 2.0 and OIDC, what they are, how they differ and even what Identity Server is and what is it used for. Today I will give more insights on what is OAuth 2.0 and OIDC are and how Identity Server relates to them.

```
1. What is OAuth 2.0
2. What is OpenID Connect
3. What is Identity Server 4
```

## 1. What is OAuth 2.0

[OAuth 2.0](https://tools.ietf.org/html/rfc6749) is an authorization protocol enabling applications to have a limited access to protected resources. The authorization is handled in the Identity provider (Idp) who is in charge of delivering an access token to the client apppication after having authenticated the resource owner (usually the user).

__Why do we need delegation?__

Let's take an example.

I have an application which you are a user from. When you log in, I want to get your profile picture from Facebook to display it on my application. 
The straight forward approach would be for my application to ask your Facebook username and password and to log into your Facebook. 
But this will cause multiple problems:

 1. you would give your credentials to a third party (my application),
 2. you wouldn't know what I will be doing with it,
 3. I will have full access to your account, there is no way for you to restrict the access to only the profile picture,
 4. it would be hard to revoke access, the only way would be to change your password. 

This is where OAuth 2.0 comes into picture. Facebook implements OAuth 2.0 which allows my application to redirect you to the official Facebook site for you to login, hence your credentials would only transit in Facebook servers, and get an access token allowing me to access __only__ the resources you have granted my applicaction to access. 

__The access token delivery providing limited access to a protected resource (like Facebook) is what OAuth 2.0 was designed for.__ 

OAuth 2.0 makes it possible via different flows; Authorization code, Implicit, Client credentials and Resource owner password flows:

- __Authorization code__ is used for clients who can keep a secret between themselves and the idp like hosted frontend.
- __Implicit flow__ is used for pure frontend clients like SPA who can't keep a secret.
- __Client credentials__ is used when the client needs to authenticate as itself, for example when your own application needs access to your own protected resource.
- __Resource owner password__ is used when the client is trusted. Be very cautious with this flow as the user credentials will need to be given to the client for the client to pass it to the idp.

OAuth 2.0 protocol also defines how clients are registered and what exchanges occur on which HTTP endpoints. 

But what it does not define is how to identify the user requesting the access token.
A common practice is to return a second token signed by the identity provider, deserializable by the recipient containing the identity of the user. But because this was not defined by the protocol, every company providing external login capabilities had to create their own way. 

Then came OIDC.

## 2. What is OpenID Connect

Initially every company was writing their own way of providing identity of the user, either by including an identifier within the access token it returned or by providing an extra token as part of the OAuth 2.0 flow.
OAuth 2.0 being so flexible, it is possible to extend it in many ways. 

From there [OpenID Connect](http://openid.net/specs/openid-connect-core-1_0.html)
 was created as a simple authentication protocol layer on top of OAuth 2.0 with the goal of providing a unified way of authenticating users.

__OIDC standardized the delivery of the `id_token` within the existing flows of OAuth 2.0.__

OIDC standardizes the way to identify the user by providing an `id_token` together with the OAuth `access_token` within the current flows available. For example in an implicit flow it will be provided at the authorization endpoint together with the access token while for an authorization code flow, it will be provided by the token endpoint.

OIDC made possible to build an identity provider as a service by providing our identity implementation to external applications just like how it is possible to use external identity providers for our own applications.

The important part to understand is that the `access_token` provided by OAuth 2.0 is for the resource to be accessed while the `id_token` is for the client application to identify the user authenticated.

## 3. What is Identity Server 4

Now that we know what is OAuth 2.0 and OpenID Connect, we need a framework which allows us to implement the protocols.

[__Identity Server 4__](https://github.com/IdentityServer/IdentityServer4) is a framework implementing OAuth 2.0 and OIDC in the .NET ecosystem and most importantly in ASP .NET Core.

In previous blog post I have covered two flow implementations:
- [Implicit](https://kimsereyblog.blogspot.sg/2017/09/implicit-flow-with-identity-server-and.html)
- [Resource owner password](https://kimsereyblog.blogspot.sg/2017/04/resourceownerpassword-with-identity.html)

But all the flows are actually supported and there are examples backing up the flows on the github of identity server.

[https://github.com/identityserver](https://github.com/identityserver)

The project is totally open sourced and extremely well maintained and is OpenID certified.

While it is responsible for the implementation of the protocols, __Identity server does not manage users__. The responsability to store users, manage their information together with credentials is left to the developers. This allows us to choose which database we want to use and how we want to store our user.
[There are already package created to support common implementation of membership systems like ASP .NET Core Identity](https://identityserver4.readthedocs.io/en/release/quickstarts/6_aspnet_identity.html).

With Identity Server 4, we will get OAuth 2.0 and OIDC, coupled with ASP .NET Core Identity for storing and managing users, we will have the full picture for authentication, authorization and management of users.

# Conclusion

Today we saw what was OAuth 2.0 and OIDC. We also decypher some of the misconceptions around authorization versus authentication and lastly we saw a .NET implementation of it, Identity Server. Hope this post was helpful! See you next time!