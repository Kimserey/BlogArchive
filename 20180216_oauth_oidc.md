# OAuth 2.0, OpenID Connect and Identity Server

When it comes to authentication and authorization, the most used standard is OAuth 2.0 with OpenID Connect.
Few weeks ago I discussed [Resource owner password](https://kimsereyblog.blogspot.sg/2017/04/resourceownerpassword-with-identity.html) and [Implicit](https://kimsereyblog.blogspot.sg/2017/09/implicit-flow-with-identity-server-and.html) flows focusing mainly on implementations with Identity Server. Today I will give more insights on what is OAuth 2.0 and OpenID Connect are and how Identity Server relates to them.

```
1. What is OAuth 2.0
2. What is OpenID Connect
3. What is Identity Server
```

## 1. What is OAuth 2.0

OAuth 2.0 is an authorization protocol enabling applications to have a limited access to protected resources. The authentication and authorization is handled in the Identity provider (Idp) who is in charge of delivering a bearer access token to client apppication after having authenticated the resource owner, usually the user.

OAuth 2.0 defines different flows of authorization which cater for different scenarios. The flows are Authorization code, Implicit, Client credentials and Resource owner password flows.

In a nutshell,

 - __Authorization code__ is used for clients who can keep a secret between themselves and the idp like hosted frontend.
 - __Implicit flow__ is used for pure frontend clients like SPA who can't keep a secret.
 - __Client credentials__ is used when the client needs to authenticate as itself, for example when your own application needs access to your own protected resource.
 - __Resource owner password__ is used when the client is trusted. Be very cautious with this flow as the user credentials will need to be given to the client for the client to pass it to the idp.

OAuth 2.0 protocol defines the different informations mandatory and optional included in the token exchanged. It defines the different HTTP endpoints 


## 2. What is OpenID Connect