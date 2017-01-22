# Authentication for WebSharper sitelet with Jwt token.

Authentication is an important part of any Web applications. Today I will explain how we can create the essential modules required to authenticate a user. This post will be composed by four parts:

```
1. What is needed for authentication
2. Password encryption and storage
3. JWT token
4. OWIN auth middleware and WebSharper OWIN selfhost
5. Glue it all together
```

# 1. What is needed for authentication

In this blog post we will see how to authenticate users with credentials userid and password.
First, we will see how to store encrypted password and how we can verify credentials against the one contained in database.
Then we will see how we can authenticate users while communicating between client (browser) and server with Jwt token.
Lastly we will see how both glued together provide a reliable authentication story.

# 2. Password encryption and storage
## 2.1 Storage

To store data I will be using Sqlite via Sqlite net pcl. If you need.  tutorial on Sqlite have a look at my previous post (link).
We first start by defining the table users which will be stored in user_accounts.db.
The users table will contain all the user identity information.

```
```

The password will also be stored but we __must encrypt it before storing it__.

## 2.2 Encryption

__Why do we need to encrypt password?__

In the event of data breach, someone may have access to your db. This could be catastrophic for users if the password is stored in plain text because lots of users reuse the same email and password for different websites. So the solution to that is to encrypt passwords.

__Salt?__

We will use a hashing algorithm via System.Security.Cryptography.Rfc2898DeriveBytes (PBKDF2) which produces a key given a password and a salt and a number of iterations.

But It is not as simple as just hashing plain password. Because some users use simple common passwords, attackers use rainbow tables which are files containing all the common password with the hashed value. If we simply hash a password, if the password is simple like "Rock123" there is chance for it to be in the rainbow table therefore if attackers have the hashed password, a simple search will match the decrypted password.

The answer to tha is to use a salt. A salt is a piece that we append to the password in order to make the final hash different than the hash which would have been generated without salt.
The purpose of the salt is to make the hashed password not retrievable from common password in rainbow tables.

Algorithm

We wil create a cryptography utility with two functions. 

 1. `Hash`
 2. `Verify`

Hash will take a plain text password and hash it.
It serves to hash the password when creating the user account and we will store the hash.
Verify will compare a plain text password with a hash password. It will be used to verify a provided password against the hash provided (which will certainly be the hash stored in db).

We first define the salt size, the key length and number of iterations. This will constitute the full hash. So the password size in term of bytes will be:

```
salt size + key length + sizeof<int>
```

The hash function will do the following:

First instantiate `PBKDF2` with the password, requested salt size and iterations.

The more iterations, the longer It will take to break the password but the longer it will take to verify the password too. So the number should balance both. Here we use 10000 iterations.

Once we have that we can extract the salt and the key. We convert the number of iterations to byte. And combine salt + key + iterations to make the hash.
Once we have the hash we can then converted to string with Convert.ToBase64String and we will be able to store this hash as text.

For the verify function, as a first step we can verify if the length of the password is the same as the one we use by converting back the hashedPassword to bytes and comparing it with the hash size. If it is different we can fail quickly.
If it is the same we need to extract the salt and iterations from the hash and then instantiate PBKDF2 given the provided password with salt and iterations and compare the result with the actual key from the hash. We do a byte by byte comparaison if both byte sequences are identical, the password is valid.

## 2.3 Store the user info

We have the db ready and the crypto module ready, now we can implement a UserRegistry to create a new user or get an existing one.

Here's the code:

We define an interface which has two main functions get and create.
Get takes a userid, we need it to retrieve a user and get its hashe password.
Create takes all the required information and save it into database. Note that we take a plain password and use our hash method to hash the password before saving it.

We now have the first part of our story - a way to create users with password, store the users info and retrieve it and verify credentials.
Next we need a way to authenticate user request from the client side.

# 3. Jwt token

Jwt token provides a way to authenticate a user without the need of password verification.
The token is a json format containing all necessary auth information.
The flow is as followed:

 1. user requests for token giving credentials
 2. server verify credentials and issue a short living token
 3. user can now make authenticated request using token

The Jwt token is composed by 3 parts, 
 - the header containing the algorithm used to generate the signature.
 - the payload containing all the information which identify the user like principal and claims.
 - the signature which is a hash produced by the payload hashed with a private key held on the server.

The algorithm used is HS256 which is a symmetric algorithm meaning the person generating and the person verifying the hash must share the key. In our case both are done by the server, we generate the signature hash on the server and when we get a token, we verify its signature on the server too.

We won't have to do all that manually as we will be using Jose-jwt which provides an implementation of the Jwt protocol and allows us to use the following functions:

```
Jose.JWT.Encode
Jose.JWT.Decode
```

Encode takes a serialized payload with the private key and algorithm (HS256).
Decode takes the token with a private key and algorithm expected and returns the serialized payload.
Decode performs all the necessary signature verification. It will throw an exception which need to be caught if the signature is wrong or the algorithm used is incorrect.

So now that we know how Jwt work, we will see how we can use it to authenticate user and for the communication between client and server.

# 4. OWIN auth middleware and WebSharper OWIN selfhost

Our Web app will be served by a WebSharper sitelet self-hosted using OWIN.
To authenticate, we will create a JWT middleware.

The auth middleware inherit from '' which is a base class from project Katana.

The important functions are:

 - `AuthenticationCoreAsync`
 - `InvokeAsync`

In `AuthenticationCoreAsync` we execute the validation of tokens and return the Principal. This will set the user identity in the owin context passed to underlying middleware.

```
```

`InvokeAsync` will be used to intercept token request and verify credentials and issue tokens.

```
```

Now that we have the auth middleware, we can place it before the sitelet. 

```
```

Every call except token will go through the authentication and when passing a valid token, the middleware below (here our sitelet) will have access to the principal and `IsAuthenticated` will return true.
So this middleware allows us to authenticate the user and to request for a token.

All we need to do now is to glue it all together

# 5. Glue it all together

In the previous sections we did the following:

```
1. Created a user accounts registry with password stored
2. Created a JWT middleware
```

Now what we need to do is to have simple register page and a simple login page.
Once we login, we will receive the token which we can either store in cookie or in token storage.

__WebSharper RPC__

One of the best feature of WebSharper is `RPC` which allows us to call server functions from the clientside code and let WebSharper handle all the serialization/deserialization in the background.
But since are authentication is token based, we need to add the token in the header. To do so we can replace the default remoting module:

```
[<JavaScript>]
module Remoting =
    open WebSharper.JavaScript

    let private originalProvider = WebSharper.Remoting.AjaxProvider

    let getToken() =
        ... get token from storage ...

    type CustomXhrProvider () =
        member this.AddHeaders(headers) =
            getToken()
            |> Option.iter (fun token -> JS.Set headers "Authorization" <| sprintf "Bearer %s" token)
            headers

        interface WebSharper.Remoting.IAjaxProvider with
            member this.Async url headers data ok err =
                originalProvider.Async url (this.AddHeaders headers) data ok err
            member this.Sync url headers data =
                originalProvider.Sync url (this.AddHeaders headers) data
            
    let installBearer() =
        WebSharper.Remoting.AjaxProvider <- CustomXhrProvider()
```

__Ajax call__

Another way to make request is true JQuery.Ajax so in order to add the token, we create an Ajax helper:

```
[<JavaScript>]
module AjaxHelper =

    type AjaxResult =
    | Success of result: obj
    | Error of errorMessage: string

    type AjaxOptions = {
        Url:         string
        RequestType: RequestType
        Headers:     (string * string) [] option
        Data:        obj option
        ContentType: string option
    } 
    with 
        static member GET =
            { RequestType = RequestType.GET;   Url = ""; Headers = None; Data = None; ContentType = Some "application/json" }
        
        static member POST =
            { AjaxOptions.GET with RequestType = RequestType.POST }
    
    let httpRequest options =
        async {
            try
                let! result = 
                    Async.FromContinuations
                    <| fun (ok, ko, _) ->
                        let settings = JQuery.AjaxSettings(
                                        Url = options.Url,
                                        Type = options.RequestType,
                                        DataType = JQuery.DataType.Json,
                                        Success = (fun (result, _, _) ->
                                                    ok result),
                                        Error = (fun (jqXHR, _, _) ->
                                                    ko (System.Exception(string jqXHR.Status)))
                                        )
                        options.ContentType |> Option.iter (fun c -> settings.ContentType <- c)
                        options.Headers     |> Option.iter (fun h -> settings.Headers <- (new Object<string>(h)))
                        options.Data        |> Option.iter (fun d -> settings.Data <- d)
                        JQuery.Ajax(settings) |> ignore
                return AjaxResult.Success result
            with ex -> 
                Console.Log <| ex.JS.ToString()
                return AjaxResult.Error ex.Message
        }
```

So let's build the registration and login now:


Congratulation! We build together a full end to end authentication story. There are more to do, like renew token for example for the JWT and for password we must allow reset password but I hope this helped you understand better what pieces are required to build an auth and use it from a WebSharper selfhost application.

# Conclusion

