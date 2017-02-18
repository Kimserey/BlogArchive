# Simple JWT authentication for WebSharper sitelet

Few weeks ago I talked about how to implement [a JWT OWIN middleware which can be used to authenticate a WebSharper sitelet](https://kimsereyblog.blogspot.co.uk/2017/01/authentication-for-websharper-sitelet.html).
Today I would like to show another simpler way of protecting a WebSharper sitelet with (again) JWT tokens, but this time, without the need of implementing a OWIN middleware which is ideal for SPA.
This post will be compose by 3 parts:

```
 1. Overview
 2. Authentication flow
 3. Implementation
```

## 1. Overview

Like our previous post, we will be using the JWT token to implement a Bearer authentication.

Check out the description in my previous post if you aren't sure how JWT works, [post here](https://kimsereyblog.blogspot.co.uk/2017/01/authentication-for-websharper-sitelet.html).

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

We can see from 4-5 that we will need a refresh token when the access token expires.

__Why do we need a refresh token?__

The refresh token role is to __refresh the access token by creating a new access token with the most up to date user principals__.

In bearer auth, when the user obtains a valid token, __the user has all the rights granted by the token as long as it is valid__. 

So if we need to restrict the user access or even lock the user, the changes will only take effect when the token expires. To prevent that, we need to only issue short living tokens. This way the token will only be valid for short period.

Without refresh token, because the token is only valid for a short time, the user will need to resend credentials every time the access token expires. To remove the need of sending back credentials, we use a refresh token.

The refresh token is a long living token. It's purpose is solely to refresh the access token. 
It is issued together with the access token but __it is only required when the access token expires__ so it is usually kept in a secure location on client side and only sent when the access token expires whereas the access token is sent on all requests needing authentication.

__What about attacks?__

Using this two tokens allows us to mitigate attacks. Access token is sent on every requests therefore the chance of it getting intercepted is the highest. But because it is only valid during a short period, it gives us more security by only leaving a small timeframe for attacks. 
For the refresh token, because it is only sent when the access token has expired and not all the time, it lessen the chances of it getting intercepted.

Now that we know the flow, let's see how we can implement it.

## 3. Implementation

First let's create a simple sitelet with the enpoints discussed above.

```
type EndPoint =
    | [<EndPoint "/data">] Data
    | [<EndPoint "/auth">] Auth of AuthEndPoint

and AuthEndPoint =
    | [<EndPoint "POST /token"; Json "credentials">] Token of credentials: Credentials
    | [<EndPoint "POST /refresh"; Json "refreshToken">] Refresh of refreshToken: string

and Credentials =
    { UserId: string
      Password: string }
```

We have a `/data` endpoint which needs to be secured, an `/auth/token` endpoint to request for the tokens and an `/auth/refresh` endpoint to refresh it.

We can take the implementation of JWT which we did [last post](https://kimsereyblog.blogspot.co.uk/2017/01/authentication-for-websharper-sitelet.html). I am just going to copy paste it for convenience.

```
type UserPrincipal =
    {
        Identity: UserIdentity
        Claims: string list
    }

and UserIdentity = 
    {
        Email: string
    }
    
type JwtPayload =
    {
        [<JsonProperty "tokenRole">]
        TokenRole: string
        [<JsonProperty "principal">]
        Principal: UserPrincipal
        [<JsonProperty "iss">]
        Issuer: string
        [<JsonProperty "sub">]
        Subject: string
        [<JsonProperty "exp">]
        Expiry: DateTime
        [<JsonProperty "iat">]
        IssuedAtTime: DateTime
        [<JsonProperty "jti">]
        Id: string
    }

[<AutoOpen>]
module Jwt =
    
    type DecodeResult =
        | Success of JwtPayload
        | Failure of DecodeError
    and DecodeError =
        /// if signature validation failed, integrity is compromised
        | IntegrityException
        /// if JWT token can't be decrypted
        | EncryptionException
        /// if JWT signature, encryption or compression algorithm is not supported
        | InvalidAlgorithmException
        | UnhandledException

    // Creates a random 256 base64 key
    let generateKey() =
        let random = new Random()
        let array: byte[] = Array.zeroCreate 256
        random.NextBytes(array)
        Convert.ToBase64String(array)

    // Server dictates the algorithm used for encode/decode to prevent vulnerability
    // https://auth0.com/blog/critical-vulnerabilities-in-json-web-token-libraries/
    let private algorithm = Jose.JwsAlgorithm.HS256

    let generate key issuer tokenRole (principal: UserPrincipal) (expiry: DateTime) =
        let payload = 
            {
                Id = Guid.NewGuid().ToString("N")
                Issuer = issuer
                Subject = principal.Identity.Email
                Expiry = expiry
                IssuedAtTime = DateTime.UtcNow
                Principal = principal
                TokenRole = tokenRole
            }
        Jose.JWT.Encode(JsonConvert.SerializeObject(payload), Convert.FromBase64String(key), algorithm)

    let decode key token =
        try
            Success <| JsonConvert.DeserializeObject<JwtPayload>(Jose.JWT.Decode(token, Convert.FromBase64String(key), algorithm))
        with
        | :? Jose.IntegrityException  -> Failure IntegrityException
        | :? Jose.EncryptionException -> Failure EncryptionException
        | :? Jose.InvalidAlgorithmException -> Failure InvalidAlgorithmException
        | _ -> Failure UnhandledException
```

There's just a slight twist compared to the implementation of the previous post, I added a `tokenRole` which will be used to differentiate between `access_token` and `refresh_token`. And I also added a special handling of all type of failure which could be caused by an invalid token.

Next we can use this implementation to build our sitelet endpoints:

```
module Site =
    // Fake private key
    let getPrivateKey() = ""
    // Fake verification
    let verify credentials = true
    // Fake retrieval of principal
    let getPrincipal userId = { Claims = []; Identity = { Email = "test@test.com" } }

    [<Website>]
    let Main =
        Application.MultiPage (fun ctx ->
            function
            | Data -> Content.Json "Nothing yet"
            | Auth endpoint ->
                match endpoint with
                | Token credentials -> 
                    if verify credentials then
                        // Credentials verified, retrieve principal
                        let principal = getPrincipal credentials.Email
                        [ Jwt.generate (getPrivateKey()) "JWTSample" "access_token" principal (DateTime.UtcNow.AddDays(1.))
                          Jwt.generate (getPrivateKey()) "JWTSample" "refresh_token" principal (DateTime.UtcNow.AddDays(7.)) ]
                        |> Content.Json
                    else Content.Unauthorized
                | Refresh refreshToken ->
                    match decode (getPrivateKey()) refreshToken with
                    | DecodeResult.Success payload ->
                        if payload.Expiry <= DateTime.UtcNow then
                            // Refresh token valid, refresh principal
                            let principal = getPrincipal payload.Principal.Identity.Email
                            [ Jwt.generate (getPrivateKey()) "JWTSample" "access_token" principal (DateTime.UtcNow.AddDays(1.))
                              Jwt.generate (getPrivateKey()) "JWTSample" "refresh_token" principal (DateTime.UtcNow.AddDays(7.)) ]
                            |> Content.Json
                        else Content.Unauthorized
                    | DecodeResult.Failure _ -> Content.Unauthorized
        )
```

Now when someone request for a token, we verify the credentials and if valid, we get the latest principal and generate an `access_token` and a `refresh_token`.
When the `access_token` expires, the user can invoke the `/auth/refresh` endpoint by passing the `refresh_token`, we then decode the token and if valid (not expired), we refresh the tokens with the latest principal.

Next we create a function to `authenticate` API calls, we also create a `ApiContext` type which will hold the user principal together with the sitelet context.

```
type ApiContext =
    { WebContext: Context<EndPoint>
      Principal: UserPrincipal }

let authenticate (ctx: Context<_>) content =
    let result =
        ctx.Request.Headers 
        |> Seq.tryFind (fun h -> h.Name = "Authorization")
        |> Option.filter (fun h -> h.Value.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        |> Option.map (fun h -> h.Value.Substring(7))
        |> Option.map (decode (getPrivateKey()))

    match result with
    | Some (DecodeResult.Success payload) ->
        // do some check on the payload like token expiry, issuer, then account locked etc..
        content { Principal = payload.Principal; WebContext = ctx }
    | _ -> Content.Unauthorized 
```

With the `authenticate` function, we can place that in our `/data` endpoint to ensure that the user is authenticated when requesting for data. 
_Note that there are multiple paths in which the token validation can possibly fail, we need to handle every possible scenarios._

```
function
 Data -> authenticate ctx (fun ctx -> "You are authenticated! " + ctx.Principal.Identity.Email |> Content.Json)
... other endpoints...
```

And that's it! Using our `authenticate` function we can authenticate each desired endpoints of the sitelet. With the `access token` and `refresh token` we can have a secured API which can be queried from an SPA or a mobile app.

# Conclusion

Today we saw how we could create a simple JWT authentication and authenticate our endpoints for a WebSharper sitelet API. We saw the differences between an access token and a refresh token and in which scenario they are used. And we implemented a full Bearer authentication flow. As usual if you have any question leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Other posts you will like!
