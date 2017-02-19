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
 /auth/register
 /auth/sendactivationemail
 /auth/activate
 /auth/token
```

### 3.1 /auth/register

```
let createAccount cfg (userRepository:UserRepository) (args: HandlersArguments.UserAccountCreateArguments) =
    if userRepository.Exists args.Email then
        None
    else
        let account =
            userRepository.Create 
                { Password = args.Password
                    Email = args.Email
                    Claims = [ args.AccountTypeClaim ]
                    FullName = args.FullName }
        
        let principal = 
            getPrincipal account
        
        // send activation token by email
        generate 
            cfg.JwtToken.PrivateKey 
            cfg.JwtToken.Issuer 
            cfg.JwtToken.TokenRoles.ActivateAccountToken 
            principal 
            (DateTime.UtcNow.AddDays(float cfg.JwtToken.ActivateAccountTokenLifespan))
        |> sendActivationEmail cfg.Smtp account.Email args.ActivateUrl 

        Some 
            { Role = cfg.JwtToken.TokenRoles.SendActivateEmailToken
              Value = 
                generate 
                    cfg.JwtToken.PrivateKey 
                    cfg.JwtToken.Issuer 
                    cfg.JwtToken.TokenRoles.SendActivateEmailToken 
                    principal 
                    (DateTime.UtcNow.AddDays(float cfg.JwtToken.SendActivateEmailTokenLifespan)) }

```

### 3.2 /auth/sendactivationemail

```
let sendActivateEmail cfg (userRepository:UserRepository) (args: SendActivationEmailArguments) =
    match decode cfg.JwtToken.TokenRoles.SendActivateEmailToken cfg.JwtToken args.SendActivationEmailToken with
    | Some payload 
        when 
            payload.TokenRole = "send_activation_email_token" 
            && not payload.Principal.Identity.IsLocked 
            && payload.Expiry > DateTime.UtcNow 
            && not payload.Principal.Identity.IsEnabled ->
        
        userRepository.GetByEmail payload.Principal.Identity.Email 
        |> Option.filter (fun account -> not account.Enabled)
        |> Option.iter (fun account ->
            generate 
                cfg.JwtToken.PrivateKey 
                cfg.JwtToken.Issuer 
                cfg.JwtToken.TokenRoles.ActivateAccountToken 
                payload.Principal 
                (DateTime.UtcNow.AddDays(float cfg.JwtToken.ActivateAccountTokenLifespan))
            |> sendActivationEmail 
                    cfg.Smtp 
                    payload.Principal.Identity.Email 
                    args.ActivateUrl
        )
    | _ ->
        // Send failed because of invalid token
        ()
```

### 3.3 /auth/activate

```
let activateAccount cfg (userRepository:UserRepository) token =
    match decode cfg.JwtToken.TokenRoles.ActivateAccountToken cfg.JwtToken token with
    | Some payload 
        when 
            payload.TokenRole = cfg.JwtToken.TokenRoles.ActivateAccountToken 
            && not payload.Principal.Identity.IsEnabled->
        
        if payload.Principal.Identity.IsLocked then 
            // Activation failed. Reason: User is locked
            None

        else if payload.Expiry <= DateTime.UtcNow then
            Some [ { Role = cfg.JwtToken.TokenRoles.SendActivateEmailToken
                     Value = 
                        generate 
                            cfg.JwtToken.PrivateKey 
                            cfg.JwtToken.Issuer 
                            cfg.JwtToken.TokenRoles.SendActivateEmailToken 
                            payload.Principal 
                            (DateTime.UtcNow.AddDays(float cfg.JwtToken.SendActivateEmailTokenLifespan)) } ]

        else
            match userRepository.GetByEmail payload.Principal.Identity.Email with
            | Some account when not account.Enabled ->
                userRepository.Activate payload.Principal.Identity.Id

                Some [ { Role = cfg.JwtToken.TokenRoles.AccessToken
                         Value = 
                            generate 
                                cfg.JwtToken.PrivateKey 
                                cfg.JwtToken.Issuer 
                                cfg.JwtToken.TokenRoles.AccessToken 
                                payload.Principal 
                                (DateTime.UtcNow.AddDays(float cfg.JwtToken.AccessTokenLifespan)) }
                       { Role = cfg.JwtToken.TokenRoles.RefreshToken
                         Value = 
                            generate 
                                cfg.JwtToken.PrivateKey 
                                cfg.JwtToken.Issuer 
                                cfg.JwtToken.TokenRoles.RefreshToken 
                                payload.Principal 
                                (DateTime.UtcNow.AddDays(float cfg.JwtToken.RefreshTokenLifespan)) } ]
            | _ ->
                // Activation failed. Reason: User is already active
                None
    | _ ->
        // Activation failed. Reason: Invalid token. [%s]" token
        None
```

### 3.4 /auth/token

```
let getToken cfg (userRepository: UserRepository) (credentials: Credentials) =
    let verify = 
        userRepository.Verify { Email = credentials.Email; Password = credentials.Password }
    
    if not verify then 
        // Sign in failed credentials provided invalid
        None

    else
        match userRepository.GetByEmail credentials.Email with
        | Some account ->
            let principal = getPrincipal account
    
            if principal.Identity.IsLocked then 
                // Sign in failed. Reason: User is locked
                None

            else if not principal.Identity.IsEnabled then
                Some [ { Role = cfg.JwtToken.TokenRoles.SendActivateEmailToken
                         Value = 
                            generate 
                                cfg.JwtToken.PrivateKey 
                                cfg.JwtToken.Issuer 
                                cfg.JwtToken.TokenRoles.SendActivateEmailToken 
                                principal 
                                (DateTime.UtcNow.AddDays(float cfg.JwtToken.SendActivateEmailTokenLifespan)) } ]
            
            else 
                Some [ { Role = cfg.JwtToken.TokenRoles.AccessToken
                         Value = 
                            generate 
                                cfg.JwtToken.PrivateKey 
                                cfg.JwtToken.Issuer 
                                cfg.JwtToken.TokenRoles.AccessToken 
                                principal 
                                (DateTime.UtcNow.AddDays(float cfg.JwtToken.AccessTokenLifespan)) }
                        { Role = cfg.JwtToken.TokenRoles.RefreshToken
                          Value = 
                            generate 
                                cfg.JwtToken.PrivateKey 
                                cfg.JwtToken.Issuer 
                                cfg.JwtToken.TokenRoles.RefreshToken 
                                principal 
                                (DateTime.UtcNow.AddDays(float cfg.JwtToken.RefreshTokenLifespan)) } ]
    
        | None ->
            // Sign in failed. Reason: User not found
            None
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
