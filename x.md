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

To store data I will be using Sqlite via Sqlite net pcl. If you need a [tutorial on Sqlite have a look at my previous post](https://kimsereyblog.blogspot.co.uk/2017/01/get-started-with-sqlite-in-from.html).
We first start by defining the table users which will be stored in user_accounts.db.
The users table will contain all the user identity information.

```
[<Table("user_accounts"); CLIMutable>]
type UserAccount =
    {
        [<Column "id"; PrimaryKey; Collation "nocase">]
        Id: string
        
        [<Column("full_name")>]
        FullName: string
        
        [<Column("email")>]
        Email: string
        
        [<Column("password")>]
        Password: string
        
        [<Column "passwordtimestamp">]                          
        PasswordTimestamp : DateTime
        
        [<Column("enabled")>]
        Enabled:bool
        
        [<Column("creation_date")>]
        CreationDate: DateTime

        [<Column("claims")>]
        Claims: string
    }

let getConnection (database: string) =
    let conn = new SQLiteConnection(database)
    conn.CreateTable<UserAccount>() |> ignore
    conn
```

The password will also be stored but we __must encrypt it before storing it__.

## 2.2 Encryption

__Why do we need to encrypt password?__

In the event of data breach, someone may have access to your db. This could be catastrophic for users if the password is stored in plain text because lots of users reuse the same email and password for different websites. So the solution to that is to encrypt passwords.

__Salt?__

We will use a hashing algorithm via `System.Security.Cryptography.Rfc2898DeriveBytes` (`PBKDF2`: Password based key derivation function 2) which produces a key given a `password` and a `salt` and a number of `iterations`.

```
open System.Security.Cryptography

let pbkdf2 = new Rfc2898DeriveBytes(password, saltSize, iterations)
```

But It is not as simple as just hashing plain password. Some users use simple passwords which make it easy for attackers to crack by using rainbow tables. Rainbow tables are files containing all the common password together with the hashed value. If we simply hash a password, if the password is simple like `Rock123` there is chance for it to be retrievable in a rainbow table.

The answer to that is to use a `salt`. __A salt is a random set of bytes that we append to the password in order to make the final hash different than the hash which would have been generated without it__.
The purpose of the salt is to make the hashed password not retrievable in rainbow tables even for simple password.

__Algorithm__

We will create a cryptography utility with two functions. 

 1. `Hash`: Hash will take a plain text password and hash it. It serves to hash the password when creating the user account and we will store the hash.
 2. `Verify`: Verify will compare a plain text password with a hash password. It will be used to verify a provided password against the hash provided (which will certainly be the hash stored in db).

We first define the salt size, the key length and number of iterations. This will constitute the full hash. So the password size in term of bytes will be:

```
let private saltSize = 32
let private keyLength = 64
let private iterations = 10000
let private hashSize = saltSize + keyLength + sizeof<int>
```

The hash function will do the following:
First instantiate `PBKDF2` with the password, requested salt size and iterations. The more iterations, the longer It will take to break the password but the longer it will take to verify the password too. So the number should balance both. Here we use 10000 iterations.
Once we have that we can extract the salt and the key. We convert the number of iterations to byte. And combine salt + key + iterations to make the hash. Once we have the hash we can then converted to string with Convert.ToBase64String and we will be able to store this hash as text.

```
// Hash password with 10k iterations
let hash password =
    use pbkdf2         = new Rfc2898DeriveBytes(password, saltSize, iterations)
    let salt           = pbkdf2.Salt
    let keyBytes       = pbkdf2.GetBytes(keyLength)
    let iterationBytes = if BitConverter.IsLittleEndian then BitConverter.GetBytes(iterations) else BitConverter.GetBytes(iterations) |> Array.rev
    let hashedPassword = Array.zeroCreate<byte> hashSize
    
    Buffer.BlockCopy(salt,           0, hashedPassword, 0,                    saltSize)
    Buffer.BlockCopy(keyBytes,       0, hashedPassword, saltSize,             keyLength)
    Buffer.BlockCopy(iterationBytes, 0, hashedPassword, saltSize + keyLength, sizeof<int>)
    
    Convert.ToBase64String(hashedPassword)
```

For the verify function, as a first step we can verify if the length of the password is the same as the one we use by converting back the hashedPassword to bytes and comparing it with the hash size. If it is different we can fail quickly.
If it is the same we need to extract the salt and iterations from the hash and then instantiate PBKDF2 given the provided password with salt and iterations and compare the result with the actual key from the hash. We do a byte by byte comparaison if both byte sequences are identical, the password is valid.

```
// verify password with 10k iterations
let verify hashedPassword (password:string) =
    let hashedPassword = Convert.FromBase64String(hashedPassword)

    if hashedPassword.Length <> hashSize then
        false
    else
        let salt = Array.zeroCreate<byte> saltSize
        let keyBytes = Array.zeroCreate<byte> keyLength
        let iterationBytes = Array.zeroCreate<byte> sizeof<int>

        Buffer.BlockCopy(hashedPassword, 0,                    salt,           0, saltSize)
        Buffer.BlockCopy(hashedPassword, saltSize,             keyBytes,       0, keyLength)
        Buffer.BlockCopy(hashedPassword, saltSize + keyLength, iterationBytes, 0, sizeof<int>);
        
        let iterations = BitConverter.ToInt32((if BitConverter.IsLittleEndian then iterationBytes else iterationBytes |> Array.rev), 0)

        use pbkdf2 = new Rfc2898DeriveBytes(password, salt, iterations)
        let challengeBytes = pbkdf2.GetBytes(keyLength)

        match Seq.compareWith (fun a b -> if a = b then 0 else 1) keyBytes challengeBytes with
        | v when v = 0 -> true
        | _ -> false
```

## 2.3 Store the user information

We have the db ready and the crypto module ready, now we can implement a UserRegistry to create a new user or get an existing one.

Here's the code:

```
module UserRegistry =

    type UserRegistryApi =
        {
            Get: UserId -> Common.UserAccount option
            Create: UserId -> Password -> FullName -> Email -> Claims -> unit
        }
    and FullName = string
    and Email = string
    and Claims = string list
        
    let private getConnection (database: string) =
        let conn = new SQLiteConnection(database)
        conn.CreateTable<UserAccount>() |> ignore
        conn

    let private get database (UserId userId) =
        use conn = getConnection database
        let user = conn.Find<UserAccount>(userId)
        if not <| Object.ReferenceEquals(user, Unchecked.defaultof<UserAccount>) then
            Some ({ Id = UserId user.Id
                    Email = user.Email
                    FullName = user.FullName
                    Password = Password user.Password
                    PasswordTimestamp = user.PasswordTimestamp
                    Enabled = user.Enabled
                    CreationDate = user.CreationDate 
                    Claims = JsonConvert.DeserializeObject<string list> user.Claims } : Common.UserAccount)
        else
            None

    let private create database (UserId userId) (Password pwd) (fullname: string) (email: string) (claims: string list) =
        use conn = getConnection database
        let timestamp = DateTime.UtcNow
        let hashedPwd = Cryptography.hash pwd
        conn.Insert 
            ({ Id = userId
               FullName = fullname
               Email = email
               Password= hashedPwd
               PasswordTimestamp = timestamp
               CreationDate = timestamp
               Enabled = true
               Claims = JsonConvert.SerializeObject claims } : UserAccount) 
        |> ignore

    let api databasePath =
        {
            Get = get databasePath
            Create = create databasePath
        }
```

We define an interface which has two main functions `Get` and `Create`.
Get takes a `userid`, we need it to retrieve a user and get its hashe password.
`Create` takes all the required information and save it into database. 

__Note that we take a plain password and use our hash method to hash the password before saving it.__

We now have the first part of our story - __a way to create users with password, store the users info and retrieve it and verify credentials__.
Next we need a way to authenticate user request from the client side.

# 3. Jwt token

Useful link: [https://jwt.io/](https://jwt.io/)

Jwt token provides a way to authenticate a user without the need of password verification. The token is a json format containing all necessary auth information.

The flow is as followed:

 1. user requests for token giving credentials
 2. server verify credentials and issue a short living token
 3. user can now make authenticated request using token

The Jwt token is composed by 3 parts, 
 - the header containing the algorithm used to generate the signature.
 - the payload containing all the information which identify the user like principal and claims.
 - the signature which is a hash produced by the payload hashed with a private key held on the server.

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcmluY2lwYWwiOnsiSWRlbnRpdHkiOnsiTmFtZSI6ImtpbXNlcmV5IiwiSXNBdXRoZW50aWNhdGVkIjp0cnVlLCJBdXRoZW50aWNhdGlvblR5cGUiOiJCZWFyZXIifSwiQ2xhaW1zIjpbImFkbWluIl19LCJpc3MiOiJjb20ua2ltc2VyZXkiLCJzdWIiOiJraW1zZXJleSIsImV4cCI6IjIwMTctMDEtMjNUMTA6NTk6NTMuMzM1MzE5MVoiLCJpYXQiOiIyMDE3LTAxLTIzVDA5OjU5OjUzLjM3NTMzNzRaIiwianRpIjoiYjcxMzJmN2IyMTJlNDc1MjgxYTc1N2UwNzFkYzFiYTcifQ.ssOuIt35piM0T1AEfNkq_Kaz6JrEzbNhJ4UdKHNZOK0

[header].[payload].[signature]
```

The algorithm used is `HS256` which is a symmetric algorithm meaning the person generating and the person verifying the hash must share the key. __In our case both are done by the server, we generate the signature hash on the server and when we get a token, we verify its signature on the server too__.

But we won't have to do all that manually as we will be using `Jose-jwt` [https://github.com/dvsekhvalnov/jose-jwt](https://github.com/dvsekhvalnov/jose-jwt) which provides an implementation of the Jwt protocol and allows us to use the following functions:

```
Jose.JWT.Encode
Jose.JWT.Decode
```

`Encode` takes a serialized payload with the private key and algorithm (HS256).
`Decode` takes the token with a private key and algorithm expected and returns the serialized payload. It also performs all the necessary signature verification. It will throw an exception which need to be caught if the signature is wrong or the algorithm used is incorrect.

```
module JwtToken =

    // Server dictates the algorithm used for encode/decode to prevent vulnerability
    // https://auth0.com/blog/critical-vulnerabilities-in-json-web-token-libraries/
    let algorithm = Jose.JwsAlgorithm.HS256

    let generate key (principal: UserPrincipal) (expiry: DateTime) =
        let payload = 
            {
                Id = Guid.NewGuid().ToString("N")
                Issuer = "com.kimserey"
                Subject = principal.Identity.Name
                Expiry = expiry
                IssuedAtTime = DateTime.UtcNow
                Principal = principal
            }
        Jose.JWT.Encode(JsonConvert.SerializeObject(payload), Convert.FromBase64String(key), algorithm)

    let decode key token =
        JsonConvert.DeserializeObject<JwtPayload>(Jose.JWT.Decode(token, Convert.FromBase64String(key), algorithm))
```

This will be our `principal` payload:

```
type UserIdentity = 
    {
        Name: string
        IsAuthenticated: bool
        AuthenticationType: string
    } with
        interface IIdentity with
            member self.AuthenticationType = self.AuthenticationType
            member self.IsAuthenticated = self.IsAuthenticated
            member self.Name = self.Name

type UserPrincipal =
    {
        Identity: UserIdentity
        Claims: string list
    } with
        interface IPrincipal with
            member self.Identity with get() = self.Identity :> IIdentity 
            member self.IsInRole role = self.Claims |> List.exists ((=) role)

type JwtPayload =
    {
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
```

`IPrincipal` and `IIdentity` are interfaces from `System.Security`. It is best to implement those because lots of API use this abstractions including `Owin` `AuthenticationMiddleware` which we will see next.

So now that we know how Jwt work, we will see how we can use it to authenticate user and for the communication between client and server.

# 4. OWIN auth middleware and WebSharper OWIN selfhost

Our Web app will be served by a WebSharper sitelet self-hosted using OWIN.
To authenticate, we will create a JWT middleware.

The auth middleware inherit from '' which is a base class from project Katana.

The important functions are:

 - `AuthenticateCoreAsync`
 - `InvokeAsync`

In `AuthenticateCoreAsync` we execute the validation of tokens and return the Principal. This will set the user identity in the owin context passed to underlying middleware.

```
// The core authentication logic which must be provided by the handler. Will be invoked at most once per request. Do not call directly, call the wrapping Authenticate method instead.(Inherited from AuthenticationHandler.)
override self.AuthenticateCoreAsync() =
    let prefix = "Bearer "

    match self.Context.Request.Headers.Get("Authorization") with
    | token when not (String.IsNullOrWhiteSpace(token)) && token.StartsWith(prefix) -> 
        let payload =
            token.Substring(prefix.Length)
            |> JwtToken.decode self.Options.PrivateKey
            
        if payload.Expiry > DateTime.UtcNow then
            Task.FromResult(null)
        else
            try 
                new AuthenticationTicket(
                    new ClaimsIdentity(
                        payload.Principal.Identity, 
                        payload.Principal.Claims 
                        |> List.map (fun claim -> Claim(ClaimTypes.Role, claim))), 
                    new AuthenticationProperties()
                )
                |> Task.FromResult
            with
            | ex ->
                
                Task.FromResult(null)
    | _ -> 
        Task.FromResult(null)
```

`InvokeAsync` will be used to intercept token request and verify credentials and issue tokens.

```
// Decides whether to invoke or not the middleware.
// If true, stop further processing.
// If false, pass through to next middleware.
override self.InvokeAsync() =
    if self.Request.Path.HasValue && self.Request.Path.Value = "/token" then
        if self.Request.ContentType = "application/json" then 
            use streamReader = new StreamReader(self.Request.Body)
            let cred = JsonConvert.DeserializeObject<Credentials>(streamReader.ReadToEnd())
            match self.Options.Authenticate cred with
            | AuthenticateResult.Success userAccount ->
                let (UserId name) = userAccount.Id
                let principal =
                    {
                        Identity = 
                            {
                                Name = name
                                IsAuthenticated = true
                                AuthenticationType = self.Options.AuthenticationType
                            }
                        Claims = userAccount.Claims
                    }

                let token = JwtToken.generate self.Options.PrivateKey principal  (DateTime.UtcNow.AddMinutes(self.Options.TokenLifeSpanInMinutes))
                use writer = new StreamWriter(self.Response.Body)
                self.Response.StatusCode <- 200
                self.Response.ContentType <- "text/plain"
                writer.WriteLine(token)
                Task.FromResult(true)
            | AuthenticateResult.Failure ->
                self.Response.StatusCode <- 401
                Task.FromResult(true)
        else
            self.Response.StatusCode <- 401
            Task.FromResult(true)
    
    else
        Task.FromResult(false)
```

Here is the full middleware implementation:

```
type JwtMiddlewareOptions(authenticate, privateKey, tokenLifeSpanInMinutes) =
    inherit AuthenticationOptions("Bearer")

    member val Authenticate = authenticate
    member val PrivateKey = privateKey
    member val TokenLifeSpanInMinutes = tokenLifeSpanInMinutes

type private JwtAuthenticationHandler() =
    inherit AuthenticationHandler<JwtMiddlewareOptions>()

    // The core authentication logic which must be provided by the handler. Will be invoked at most once per request. Do not call directly, call the wrapping Authenticate method instead.(Inherited from AuthenticationHandler.)
    override self.AuthenticateCoreAsync() =
        let prefix = "Bearer "

        match self.Context.Request.Headers.Get("Authorization") with
        | token when not (String.IsNullOrWhiteSpace(token)) && token.StartsWith(prefix) -> 
            let payload =
                token.Substring(prefix.Length)
                |> JwtToken.decode self.Options.PrivateKey
                
            if payload.Expiry > DateTime.UtcNow then
                Task.FromResult(null)
            else
                try 
                    new AuthenticationTicket(
                        new ClaimsIdentity(
                            payload.Principal.Identity, 
                            payload.Principal.Claims 
                            |> List.map (fun claim -> Claim(ClaimTypes.Role, claim))), 
                        new AuthenticationProperties()
                    )
                    |> Task.FromResult
                with
                | ex ->
                    
                    Task.FromResult(null)
        | _ -> 
            Task.FromResult(null)

    // Decides whether to invoke or not the middleware.
    // If true, stop further processing.
    // If false, pass through to next middleware.
    override self.InvokeAsync() =
        if self.Request.Path.HasValue && self.Request.Path.Value = "/token" then
            if self.Request.ContentType = "application/json" then 
                use streamReader = new StreamReader(self.Request.Body)
                let cred = JsonConvert.DeserializeObject<Credentials>(streamReader.ReadToEnd())
                match self.Options.Authenticate cred with
                | AuthenticateResult.Success userAccount ->
                    let (UserId name) = userAccount.Id
                    let principal =
                        {
                            Identity = 
                                {
                                    Name = name
                                    IsAuthenticated = true
                                    AuthenticationType = self.Options.AuthenticationType
                                }
                            Claims = userAccount.Claims
                        }

                    let token = JwtToken.generate self.Options.PrivateKey principal  (DateTime.UtcNow.AddMinutes(self.Options.TokenLifeSpanInMinutes))
                    use writer = new StreamWriter(self.Response.Body)
                    self.Response.StatusCode <- 200
                    self.Response.ContentType <- "text/plain"
                    writer.WriteLine(token)
                    Task.FromResult(true)
                | AuthenticateResult.Failure ->
                    self.Response.StatusCode <- 401
                    Task.FromResult(true)
            else
                self.Response.StatusCode <- 401
                Task.FromResult(true)
        
        else
            Task.FromResult(false)
            

type JwtMiddleware(next, options) =
    inherit AuthenticationMiddleware<JwtMiddlewareOptions>(next, options)

    override __.CreateHandler() =
        JwtAuthenticationHandler() :> AuthenticationHandler<JwtMiddlewareOptions>

```

__Bearer, what's that?__

`Bearer` is the name of the authentication token protocol used. When sending the token, we prefix it with `Bearer` -> `Authorization: Bearer [token]` and the server will know what the token is for and how to handle it.

Now that we have the auth middleware, we can place it before the sitelet. 

```
app.Use<JwtMiddleware>(
        new JwtMiddlewareOptions(
            authenticator.Authenticate, 
            coreCfg.Jwt.PrivateKey, 
            float coreCfg.Jwt.TokenLifeSpanInMinutes
        )
    ) 
   .UseWebSharper(webSharperOptions)
   .UseStaticFiles(StaticFileOptions(FileSystem = PhysicalFileSystem(coreCfg.Sitelet.RootDir)))
```

Here I am passing some configuration which you can find in the source code sample [here](https://github.com/Kimserey/JwtWebSharperSitelet/blob/master/Website/EntryPoint.fs).

Every call except `/token` will go through the authentication and when passing a valid token, the middleware below (here our sitelet) will have access to the principal and `IsAuthenticated` will return true.

_In a `SPA` context, all `GET` requests for pages will not need to be secured but all `API` calls for `data` will be done through Ajax queries and will need authentication._

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

