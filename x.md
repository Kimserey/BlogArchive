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
 1. /auth/register
 2. /auth/sendactivationemail
 3. /auth/activate
 4. /auth/token
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

### 3.5 Put it all together

We first put all the functions define abose in a module called `Handlers` and call each function from the corresponding endpoint.
We assume that we have a `UserRepository` containing the function required by the handlers and we provide a configuration containing all the configuration needed.

_I haven't copied here the UserRepository and the Configuration because those are most likely specific to your app. You will need different sort of configuration and it is us to you to decide up to how much you want your application to be configurable._

```
type SiteEndPoint =
  | [<EndPoint "/auth">] Auth of AuthEndPoint

and AuthEndPoint =
  | [<EndPoint "POST /token"; Json "credentials">] Token of credentials: Credentials
  | [<EndPoint "POST /refresh"; Json "token">] Refresh of token: string
  | [<EndPoint "POST /register"; Json "registration">] Register of registration: HandlersArguments.UserAccountCreateArguments
  | [<EndPoint "POST /activate"; Json "token">] Activate of token: string
  | [<EndPoint "POST /sendactivation"; Json "sendActivationEmail">] SendActivationEmail of sendActivationEmail: HandlersArguments.SendActivationEmailArguments


Sitelet.Infer (fun ctx endpoint -> 
    match endpoint with
    | Auth endpoint ->
        match endpoint with
        | Token credentials -> 
            match Handlers.getToken cfg users credentials with
            | Some tokens -> Content.Json tokens
            | None -> Content.Unauthorized

        | Refresh refreshToken ->
            match Handlers.refreshToken cfg users refreshToken with
            | Some tokens -> Content.Json tokens
            | None -> Content.Unauthorized
            
        | Register registration ->
            match Handlers.createAccount cfg users registration with
            | Some token -> Content.Json token
            | None -> Content.Unauthorized
        
        | Activate activateToken ->
            match Handlers.activateAccount cfg users activateToken with
            | Some tokens -> Content.Json tokens
            | None -> Content.Unauthorized

        | SendActivationEmail sendActivationArgs ->
            Handlers.sendActivateEmail cfg users sendActivationArgs
            Content.Json ()
)
```

Now we have the API ready for registration, what we need to do next is to define the SPA endpoints which complement the API endpoints.

## 4. Site endpoints

From the overview, we can extract 4 endpoints needed for the webapp:

```
 1. /signin
 2. /register
 3. /register/success/[send_activation_email_token]
 4. /register/activate/[activation_token]
 5. /register/activate/fail/[send_activation_email_token]
```

So it translate to the following route:

```
type EndPoint =
    | SignIn
    | Register
    | RegisterSuccess    of sendActivationEmailToken: string
    | RegisterActivation of activateToken: string
    | ActivationFailure  of sendActivationEmailToken: string


let route =
    RouteMap.Create 
        (function
            | SignIn -> [ "signin" ]
            | Register -> [ "register" ]
            | RegisterSuccess sendActivationEmailToken -> [ "register"; "success"; sendActivationEmailToken ]
            | RegisterActivation activateToken -> [ "register"; "activate"; activateToken ]
            | ActivationFailure sendActivationEmailToken -> [ "register"; "activate"; "fail"; sendActivationEmailToken ])
        (function
            | [ "signin" ] -> SignIn
            | [ "register" ] -> Register
            | [ "register"; "success"; sendActivationEmailToken ] -> RegisterSuccess sendActivationEmailToken
            | [ "register"; "activate"; activateToken ]  -> RegisterActivation activateToken
            | [ "register"; "activate"; "fail"; sendActivationEmailToken ] -> ActivationFailure sendActivationEmailToken
            | _ -> SignIn)
    |> RouteMap.Install
```

### 4.1 /signin

```
let renderSignInForm postHref redirectActivationHref redirectSuccessHref =
    let form = 
        { Key = "login"
          Type = Clear
          Elements = 
            [ EmailInput ("Email", "Email", NotEmpty)
              PasswordInput ("Password", "Password", NotEmpty) ]
          Submitter =
            SignIn (postHref, redirectActivationHref, redirectSuccessHref, "SIGN IN") }

    divAttr
        [ attr.``class`` "card mb-4" ]
        [ divAttr
            [ attr.``class`` "card-block" ]
            [ divAttr
                    [ attr.``class`` "display-4 text-center" ]
                    [ iAttr [ attr.``class`` "fa fa-user-circle-o mr-3 text-primary" ] []
                      text "Sign in" ]
              renderForm form ] ] :> Doc
```

### 4.2 /register

```
let renderRegister postHref redirectHref activateHref =
    let form =
        { Key = "registration"
          Type = Clear
          Elements = 
            [ EmailInput ("Email", "Email", NotEmpty)
                TextInput ("FullName", "Full name", NotEmpty)
                PasswordInput ("Password", "Password", NotEmpty)
                PasswordInput ("ConfirmPassword", "Confirm password", NotEmpty)
                HiddenField ("ActivateUrl", activateHref) ]
          Submitter = 
            Register (postHref, redirectHref, "REGISTER") }
    
    divAttr
        [ attr.``class`` "card mb-4" ]
        [ divAttr
            [ attr.``class`` "card-block" ]
            [ divAttr
                [ attr.``class`` "display-4 text-center" ]
                [ iAttr [ attr.``class`` "fa fa-thumbs-o-up text-primary mr-3" ] []
                  text "Register" ]
                
              renderForm form ] ] :> Doc
```

### 4.3 /register/success/[send_activation_email_token]

```
let private orderSendActivationEmail sendActivationEmailToken activationAbsoluteUrl =
    AjaxHelper.postJson "/auth/sendactivation" { SendActivationEmailToken = sendActivationEmailToken; ActivateUrl = activationAbsoluteUrl }
    |> Async.Ignore
    |> Async.StartImmediate
    
let renderRegisterSuccess sendActivationEmailToken =
    divAttr
        [ attr.``class`` "alert-success text-center p-3" ]
        [ strong [ text "Your account was created but is not yet verified! " ]
          text "An email has been sent to your email address."
          br []
          text "Please follow the instruction in the email to activate your account."
          br []
          aAttr 
            [ attr.href "#"
                on.click (fun _ ev -> ev.PreventDefault(); orderSendActivationEmail sendActivationEmailToken) ] 
            [ text "Click here to resend the activation email." ] ] :> Doc
```

### 4.4 /register/activate/[activate_token]

```
let renderRegisterActivation activateToken =
    let msg = Var.Create (text "Please wait a second while we activate your account.")
    
    let activate (token: string) =
        async {
            let! res = AjaxHelper.postJson "/auth/activate" token
            
            match res with
            | AjaxHelper.Success token -> 
                let tokens = As<Token []>(token)
                match tokens |> Array.toList with
                | accessToken::refreshToken::_ ->
                    // token can be stored here
                    JS.Window.Location.Href <- "#" //redirect to log in
                | sendActivationToken::_ ->
                    JS.Window.Location.Href <- "#registration/activate/fail/" + sendActivationToken.Value
                | [] -> 
                    msg.Value <- Doc.Concat [ text "Sorry, an unexpected error occured."; br []; text "Refresh the page or contact us directly if the problem persists." ]
            | _ ->  
                msg.Value <- Doc.Concat [ text "Sorry, an unexpected error occured."; br []; text "Refresh the page or contact us directly if the problem persists." ]
        }
        |> Async.Ignore
        |> Async.StartImmediate
    
    divAttr 
        [ attr.``class`` "text-center alert-info p-3"
          on.afterRender (fun _ -> activate activateToken) ] 
        [ msg.View |> Doc.BindView id ] :> Doc
```

### 4.5 /register/activate/fail/[send_activation_email_token]

```
let renderActivationFail sendActivationEmailToken activationAbsoluteUrl =
    divAttr 
        [ attr.``class`` "alert-warning p-3" ] 
        [ strong [ text "Sorry, " ]
          text "it seems like the link has expired. But no worries, you can resend the activation email by clicking the link below."
          br []
          aAttr 
            [ attr.href "#"
              on.click (fun _ ev -> ev.PreventDefault(); orderSendActivationEmail sendActivationEmailToken activationAbsoluteUrl) ] 
            [ text "Click here to resend the activation email." ] ] :> Doc
```

### 4.6 Put it all together

Just as the API, we put all the functions defined above under a module called `Renderers` and call the proper functions in the correct routes.

```
// This url needs to be abolute because it will be used as a callback from the email
let activationAbsoluteUrl = JS.Window.Location.origin + "#register/activate"
let registerSuccessRelativeUrl = "#register/success"

route.View
    |> Doc.BindView (
        function
        | SignIn -> 
            Renderers.renderSignInForm "/auth/token" registerSuccessRelativeUrl "#"
        
        | Register -> 
            Renderers.renderRegister "/auth/register" registerSuccessRelativeUrl activationAbsoluteUrl
        
        | RegisterSuccess sendActivationEmailToken -> 
            Renderers.renderRegisterSuccess sendActivationEmailToken activationAbsoluteUrl
        
        | RegisterActivation activateToken -> 
            Renderers.renderRegisterActivation activateToken

        | ActivationFailure sendActivationEmailToken ->
            Renderers.renderActivationFail sendActivationEmailToken activationAbsoluteUrl
    )
```

# Conclusion
