# Single page application in F# with WebSharper UI.Next

Last week I wrote a post on [how I handle latency and exception while interacting with REST api in F# using computation expression and WebSharper](http://kimsereyblog.blogspot.sg/2015/08/computation-expression-approach-for.html).
The first part on computation expression was quite detailed but the second part on WebSharper was mostly code snippets with very little explanations.
Today I want to rectify that by showing you how I am using WebSharper UI.Next to build a simplistic single page application (`SPA`).

Here is the result of what we will do:
![alt "Result SPA"](http://2.bp.blogspot.com/-E0jTQw-Cn-g/VdrRDrNI4FI/AAAAAAAAACY/oKAjZ0CE1Iw/s1600/portal.gif)

In this post I will explain few points which were hard for me to grasp when I started to code in F# with WebSharper. By writing this post, I hope that it will help you and that you won't need to go through the same _flip table_ phase as I did! So put on your seat belt and enjoy the ride.

In this post I will explain to you:
1. The basic of `UI.Next` in order for you to be able to understand the code
2. How I manage routing for the `SPA`
3. How I split my webapp and organize my code
4. How to put everything together

First let's start with some basic explanation about UI.Next.

## Basic of UI.Next

I will give a brief explanation of what you need to know to follow this post. You can refer to the [`UI.Next` documentation](http://websharper.com/docs/ui.next) for further explanation or the [`UI.Next` sample project](https://github.com/intellifactory/websharper.ui.next.samples) for a larger scale project. In order to understand the code in this post, we will need to first understand:
- How to build HTML with `UI.Next` in F#
- What is a `Var` and a `View` in `UI.Next`

### How to build HTML with UI.Next in F#
 In `UI.Next`, we create HTML the same way as we would do it in a `.html` page. `UI.Next`exposes functions that let us create all the HTML markup; like div, button, a and family. It respects the same name as the HTML markup. It is very easy to recreate a HTML page in F# using `UI.Next`. For example this code in F#:
```
div [ p [ text "hello world" ] ]
```
produces this in HTML:
```
<div><p>hello world</p></div>
```
You see? `div` for `<div>` and `p` for `<p>`. It's the same! In fact for each HTML markup tag, `UI.Next` has an equivalent in F#. Each one of those takes as parameter the body of the markup tag. `text` is a function that change a string to a `doc` element directly and allows us to embed it in our HTML. To add attributes, you must use the tag name followed by `Attr`. For example `div` will be `divAttr`. Here is how we add attributes:
```
divAttr [attr.``class`` "my-class"] [text "hello"]
```
`attr` exposes all the common attributes: `class`, `id`, `name` etc... If there is an attribute that you can't find, you can create it using `Attr.Create name value`.
```
divAttr [attr.``class`` "my-class"
         Attr.Create "data-hello" "hello"] [text "hello"]
```
Will result in:
```
<div class="my-class" data-hello="hello">hello</div>
```
There is also some functions exposed by the `Doc` type that allow us to create button or link in a more straight forward way like `Doc.Button` or `Doc.Link`. Alright now that you understand everything about building `doc`s, let's create some helper functions that will help us to create divs, buttons, jumbotrons and family tags from `Bootstrap`! Let's start with a `row`. How do we do a `row` with `Bootstrap`? Well that's easy:
```
<div class="row"></div>
```
So how does it look like in `UI.Next`? Let's see:
```
let bsRow body = divAttr [attr.``class`` "row"] body
```
Easy right? How about a jumbotron?
```
<div class="jumbotron">
  <div class="container">
    <h1>...title...</h1>
    ...body...
  </div>
</div>

let bsJumbotron title body =
   divAttr [attr.``class`` "jumbotron"]
           [divAttr [attr.``class`` "container"]
                    [h1 [text title]
                     body]]
```
"That is too easy", I can hear you say. Okay let's try something that involves logic. In the gif result, we can see that we are using buttons which have different classes: `default` and `primary`. On top of that, the login page button takes the full width whereas the other buttons are inline. Given those details, how can we model that in `UI.Next`? Let's try it:
```
module Button =
  type private ButtonColor =
  | Default
  | Primary

  type private ButtonStyle =
  | FullWidth
  | Inline

  let private makeButton txt btnColor btnStyle =
    let classes = [yield "btn"
                   yield match btnColor with
                         | Default -> "btn-default"
                         | Primary -> "btn-primary"
                   yield match btnStyle with
                         | FullWidth -> "full"
                         | Inline -> "inline"]
                  |> String.concat (" ")
    Doc.Button
    <| txt
    <| [attr.``class`` classes
        attr.``type`` "submit"]
    <| action

  let bsBtnDefaultInline txt action =
    makeButton txt ButtonColor.Default ButtonStyle.Inline action

  let bsBtnDefaultFull txt action =
    makeButton txt ButtonColor.Default ButtonStyle.FullWidth action

  let bsBtnPrimaryInline txt action =
    makeButton txt ButtonColor.Primary ButtonStyle.Inline action

  let bsBtnPrimaryFull txt action =
    makeButton txt ButtonColor.Primary ButtonStyle.FullWidth action
```
We start by defining two types: `ButtonColor` and `ButtonStyle`. Then we create a general function to make the button and `yield` different classes based on the choices given in parameter. We then define our different functions to create default button or primary button, inline or full width. 

Let's finish this example with the navbar, if we look closely at the [`HTML` of a navbar](http://getbootstrap.com/components/#navbar) we can see that it is composed by two parts: a `header` and a `menu collapsible`. Within the `menu collapsible` there is two part as well: the `left links` and `right links` _(one good thing is that UI.Next forces me to look and understand what I write for the HTML, honestly I never looked at what was the composition of a navbar until today)_. Let's put that into the code:
```
let bsNav brand leftLinks rightLinks =
        let navHeader =
            divAttr [attr.``class`` "navbar-header"]
                    [buttonAttr [attr.``class`` "navbar-toggle collapsed"
                                 Attr.Create "data-toggle" "collapse"
                                 Attr.Create "data-target" "#menu"
                                 Attr.Create "aria-expanded" "false"]
                                [spanAttr [attr.``class`` "sr-only"] []
                                 spanAttr [attr.``class`` "icon-bar"] []
                                 spanAttr [attr.``class`` "icon-bar"] []
                                 spanAttr [attr.``class`` "icon-bar"] []]
                     aAttr [attr.``class`` "navbar-brand title"
                            attr.href "#"]
                           [text brand]]

        let navMenu =
            divAttr [attr.``class`` "collapse navbar-collapse"
                     attr.id "menu"]
                    [ulAttr [attr.``class`` "nav navbar-nav"] [leftLinks]
                     ulAttr [attr.``class`` "nav navbar-nav navbar-right"] [rightLinks]]

        navAttr [attr.``class`` "navbar navbar-default"]
                [divAttr [attr.``class`` "container-fluid"]
                         [navHeader
                          navMenu]] :> Doc
```
It looks pretty much like what we described. We have a `navHeader` and a `navMenu` which in turn contains `leftLinks` and `rightLinks`. `leftLinks` and `rightLinks` are given as parameters of the function as they are tight to actions unrelated to "Bootstrap's stuff". So for the rest of the post when you see some functions prepended with `bs` remember that it doesn't stand for bulls**t but for bootstrap and it's our own methods! Alright, I think you got it. Now you know everything about creating your HTML from `F#`, let's try to understand what is a `Var` and a `View`.

### What is a UI.Next Var and a View?
A `Var` is a `variable` which can be changed overtime. It can be created using `Var.Create`, it can be set using `Var.Set` and __most importantly it exposes a `View`__. A `View` is a direct representation of the `Var` that you can embed in a `Doc` (in your HTML) and whenever `Var` changes, it will be reflected in the `Doc`. The good thing is that `UI.Next` has a bunch of methods that enable all the power of `Views`: `View.Const`, `View.Map`, `View.Bind`, `View.Convert` and [many more](http://websharper.com/docs/ui.next)! 

In this post we will be using `View.Map`. `View.Map` takes __a function which takes a parameter of type `'a` and return a type `'b`__ and __a parameter of type `View<'a>`__ and return __a type `View<'b>`__:
```
View.Map: f:('a -> 'b) -> View<'a> -> View<'b>`
```
This means that `View.Map` takes a `View<'a>` and map it to a `View<'b>` by applying a transformation `f`. The advantage of composing with `View`s is that as soon as we set the `Var<'a>` projected by `View<'a>`, `f` will be re-executed and `View<'b>` will reflect the changes. If you have `View<'b>` embedded in one of your `Doc`, you will see the changes. 

Lastly `Var` can be used to create `Input` for example to create a text input:
```
let txtInput = Doc.Input [attr.placeHolder "Text input"] myVar
```
As soon as the input changes, the `View` exposed by `myVar` will reflect the changes. 

Okay now that we are clear about what is `Var` and `View`, let's see how we can use it. If you look at the result gif, we can see that there is a form in the `Login` page. It contains the usual username and password input fields and a button to log in and when an error occurs, a message will be displayed at the top of the form. To create this we need three `Var<string>`: for username, for the password and for the error message.
```
let rvUsername = Var.Create ""
let rvPassword = Var.Create ""
let rvErr = Var.Create ""
```
I prepended the `Var`s with `rv` which stands for reactive variable. Next we build our inputs (remember all `bs` stuff is our own, you can find the complete source code at the end):
```
let nameInput = bsInput "Username" rvUsername
let pwdInput  = bsPasswordInput "Password" rvPassword
let errDiv    = rvErr.View
                |> View.Map(fun err -> if err = "" then Doc.Empty 
                                       else bsAlertDanger err)
                |> Doc.EmbedView
```
`nameInput` and `pwdInput` are inputs that will alter the `Var`s passed as parameter. To build the `errDiv`, we are checking the `rvErr.View` and are using `View.Map` to return either an empty `Doc` when there is no error message or return a bootstrap alert div with the message when an error occurs. 

Next we need a button to log in. Let's start by creating a function to login:
```
let private login rvUsername rvPassword rvLoginError go () =
        async {
            let! login = api.Login { Username = Var.Get rvUsername
                                     Password = Var.Get rvPassword }
            match login with
            | AsyncApi.Failure err ->
                Var.Set rvLoginError "You may have keyed in an invalid Username or Password. Please try again."
                api.Logout()
            | _ -> ()
            return login
        }
        |> AsyncApi.map (fun _ -> go ClientRoutes.Home)
        |> AsyncApi.start
//login: Var<string> -> Var<string> -> Var<string> -> (Page -> unit) -> unit -> unit
```
We are going to assume that we have an `api` that has a `login` and a `logout` method. `login` takes a username and a password and returns an `Async<ApiResult<unit>>` ([looks familiar](http://kimsereyblog.blogspot.sg/2015/08/computation-expression-approach-for.html)). We also assume that we have a type `ClientRoutes` somewhere which is a discriminated union of all our pages `Home|Login|Users|Claims`. `go` is a function which allows us to go to the next page, we will discuss more about it later just assume that it works for now. Notice the unit `()` at the end of the parameter list, this is in order for us to make a __partial application__ for `login`. Now let's create our button:
```
Button.bsBtnDefaultFull "Log in" (login rvUsername rvPassword rvErr go)
```
`bsBtnDefaultFull` is our own button that we defined earlier. It takes a `string` and a function of type `unit -> unit`. We pass in `login rvUsername rvPassword rvErr go` which is a partially applied function of type `unit -> unit` (thanks to out last parameter `()` in `login`). Finally we put everything together:
```
let doc go =
    let rvUsername = Var.Create ""
    let rvPassword = Var.Create ""
    let rvErr = Var.Create ""

    let nameInput = bsInput "Username" rvUsername
    let pwdInput = bsPasswordInput "Password" rvPassword
    let errDiv = rvErr.View
                 |> View.Map(fun err -> if err = "" then Doc.Empty
                                        else bsAlertDanger err)
                 |> Doc.EmbedView

    let buttons =
        bsPanelDefault
            [ form [ errDiv
                     nameInput
                     pwdInput
                     Button.bsBtnDefaultFull "Log in"
                                             (login rvUsername rvPassword rvErr go) ] ]
    bsRow [ bsCol4 [ Doc.Empty ]
            bsCol4 [ h1Attr [attr.``class`` "title"] [text "admin portal"]
                     buttons ]
            bsCol4 [ Doc.Empty ] ]
```
Here what we have done so far:

![alt "Login page"](http://4.bp.blogspot.com/-13jfHBOVzD0/VdvlIQ9S-CI/AAAAAAAAACo/2p-IhYDUbok/s1600/loginPage.PNG "Login page")

Nice right? We are done with `UI.Next`! We know everything for now... Or do we? Well no there is one last part missing... The `router`!
## UI.Next Router

In a `SPA`, the content is dynamically created in JavaScript. Meaning the user navigate to our URL, and we _fake_ the page changes by manipulating the `DOM` to make smooth changes. This behaviour introduces a problem; we only have one single URL. Why is it a problem? Well it doesn't work very well with browsers. On the browser we need to be able to hit the previous button or next button, we need to be able to navigate in the history and also be able to bookmark. But with a single URL the browser sees one page (which is why we call it "single" page app). You might have navigated in tons of pages within your `SPA` but as soon as you hit previous, you will just be redirected to the previous site you visited. To fix this we need each of our pages to have its own URL. So how do we do that? We use `UI.Next Router`! With the help of the router we will have `//localhost/#`, `//localhost/#login`, `//localhost/#claims` and `//localhost/#users`. And we can now bookmark those URLs or do whatever we want. So how do we use `UI.Next Router`? We need to:
1. Define a route map
2. Install the route map
3. Use the variable Var<ClientRoutes.Page> to navigate

_This is not the only way to define routes but it is the easiest [I found](http://websharper.com/question/79929/javascript-cannot-read-property-0-of-undefined-when-using-ui-next-router) recommended to me by [@inchester23](https://twitter.com/inchester23)._

### Defining the route map
A route map consists of a `map` and a `reverse map` of the website routes. In our case we have 4 routes: Home, Login, Claims and Users. Let's start by creating a discriminated union which hold our pages. We will put our routes code in a module called `ClientRoutes`:
```
[<JavaScript>]
module ClientRoutes =
    type Page =
        | Home
        | Claims
        | Users
        | Login
        override this.ToString() =
            match this with
            | Home -> "Home"
            | Claims -> "Claims"
            | Users -> "Users"
            | Login -> "Login"
```
Now it's time to create our `routeMap`. We need to call the `RouteMap.Create` function to create it:
```
let routeMap = RouteMap.Create map reverseMap
//RouteMap.Create: ('page -> string list) -> (string list -> 'page) -> RouteMap<'T>
```
From the function type we can see that our `map` has a type `'page -> string list`, it takes a `page type` and returns a `string list` which represents the route. The `reverseMap` is the opposite, it takes a `string list` which represents the route and returns the `page type`. Here's what the `map` and `reverseMap` definition:
```
let private map =
    function
    | Home -> []
    | Claims -> [ "claims" ]
    | Users -> [ "users" ]
    | Login -> [ "login" ]

let private reverMap =
    function
    | [] -> Home
    | [ "home" ] -> Home
    | [ "claims" ] -> Claims
    | [ "users" ] -> Users
    | [ "login" ] -> Login
    | _ -> failwith "404"
```
Notice that we can add extra mappings, in the `reverseMap` I redirected `/#home` to `/#` and notice the `wildcard` which will throw a 404. Alright we got the `routeMap` ready. Next step is to install it.

### Install the route map

Installing a `routeMap` has to happen one time in the lifetime of the app. It is done by calling `RouteMap.Install`. We will expose an `install` function from our `ClientRoutes module` and call `RouteMap.Install`. Here is what the documentation says about `RouteMap.Install`:
```
/// Installs the map globally, tying it to the hash-route of the current window.
/// Call once per app.
static member Install : RouteMap<'T> -> Var<'T>
```
In other words, it will tie our routes to the hash part of the URL.
```
[ "home" ]         ==>> /#home
[ "users"; "kim" ] ==>> /#users/kim
```
So let's expose our `install` method to be called from our entry point. We will pipe the creation of the `routeMap` to its installation:
```
let install () =
  RouteMap.Create map reverMap
  |> RouteMap.Install
```
Cool, we end up with the following `ClientRoutes` module:
```
[<JavaScript>]
module ClientRoutes =
    type Page =
        | Home
        | Claims
        | Users
        | Login
        override this.ToString() =
            match this with
            | Home -> "Home"
            | Claims -> "Claims"
            | Users -> "Users"
            | Login -> "Login"

    let private map =
        function
        | Home -> []
        | Claims -> [ "claims" ]
        | Users -> [ "users" ]
        | Login -> [ "login" ]

    let private reverMap =
        function
        | [] -> Home
        | [ "home" ] -> Home
        | [ "claims" ] -> Claims
        | [ "users" ] -> Users
        | [ "login" ] -> Login
        | _ -> failwith "404"

    let install () =
        RouteMap.Create map reverMap
        |> RouteMap.Install
```
Looking back at definition of `RouteMap.Install`: `RouteMap<'T> -> Var<'T>`, we can see that it returns a `Var<'T>` which is a variable that holds the current `route` active in the browser. You might have guessed it already, we will use this `Var` to navigate, change URL and change pages!

### Navigate using Var<ClientRoutes.Page>

To navigate we will use the variable `Var<ClientRoutes.Page>` by changing it using `Var.Set`. This will automatically change the browser URL. But we don't want to just change the browser URL; we want to change the current page and display the appropriate page as well! So what should we do? Well we should tie ourself to the changes of `Var<ClientRoutes.Page>` by watching its `View` and passing a function to `View.Map` which will trigger the page change. 

So we know that we will need to somehow change the router `Var` from lots of places; we need it in the navbar, we need it for links within the site and for buttons as well. But we also know that mutable variable passed around accross the app is not a good idea. Lucky us, `Var.Set` is a curryed function that allows us to define it partially like so:
```
let router = ClientRoutes.install() // router: Var<ClientRoutes.Page>

let go = Var.Set router // Var.Set: Var<ClientRoutes.Page> -> ClientRoutes.Page -> unit
                        // go: ClientRoutes.Page -> unit
```
Instead of passing `router` around, we will pass `go`. It will allow us protect ourself from others changing directly the `router`. We will always be in charge of modifying the `router` as others won't be able to set it directly but what they will be able to do is to call our method to set it _(this concept is also known as closure)_. Great, with the `go` function we can now pass it around safely. We are ready now to define our entry point, the `Main` function:
```
let Main =
        let router = ClientRoutes.install()
        let doc =
            router.View
            |> View.Map(fun page ->
                   let go = Var.Set router
                   let addNavBar body =
                       [ NavBarPage.doc router.View go
                         body ]
                       |> Doc.Concat
                   let embedInContainer body = bsContainer [ body ]

                   match page with
                   | ClientRoutes.Login ->
                       LoginPage.doc go
                       |> embedInContainer :> Doc
                   | ClientRoutes.Home ->
                       HomePage.doc go
                       |> embedInContainer
                       |> addNavBar
                   | ClientRoutes.Claims ->
                       ClaimsPage.doc go
                       |> embedInContainer
                       |> addNavBar
                   | ClientRoutes.Users ->
                       UsersPage.doc go
                       |> embedInContainer
                       |> addNavBar)
            |> Doc.EmbedView
        Doc.RunById "main" doc
```
We first install the route with `let router = ClientRoutes.install()` then we create our `doc` by checking the changes of the `router.View`. Everytime the `router` changes we run a pattern matching and depending on the `page`, we show a different `doc`. At the end of `Main`, we call `Doc.RunById "main" doc` which replaces the tag with `id="main"` by the `doc` we give in parameter. We can see here that we have four modules which corresponds to four pages: `LoginPage`, `HomePage`, `ClaimsPage` and `UsersPage`. It brings us to the next point: how to split code in a webapp.

## How I split my webapp and organize my code

_I have not yet worked on an enterprise size F# project and am myself a novice in F# and WebSharper. This might not be the correct way to split code but hey! I feel that this is a nice way to do it that's why I would like to share it with you! If you have suggestions, hit me on twitter_ [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).

Cool, now that we are clear about that, let's start! We already did the `Login` page earlier so let's do the `Home` page now. From the gif, we can see that the home page contains two buttons: one to jump to the `Claims` page and another one to jump to the `Users` page. so let's do it:
```
[<JavaScript>]
module HomePage =
    let doc go =
        bsJumbotron "Hello,"
                    ([p [text "Welcome to the admin portal v1.0."] :> Doc
                      Button.bsBtnPrimaryInline "View claims"
                                                (fun () -> go ClientRoutes.Claims) :> Doc
                      Button.bsBtnPrimaryInline "View users"
                                                (fun () -> go ClientRoutes.Users) :> Doc]
                     |> Doc.Concat)
```
The page contains a `jumbotron` with a title, a paragraph with two buttons. Each button brings to its respective page. We use `go` to set the page which will trigger the page change in the `Main doc`. We can now create the `home page doc` by calling the function `HomePage.doc` and passing the `go` function as parameter.
```
let go = ...
let homePageDoc = HomePage.doc go
```
We now do the same for each pages and define it in its own module. `Claims` and `Users` only contain a `jumbotron` so it is faily easy to do:
```
[<JavaScript>]
module ClaimsPage =
    let doc go =
        bsJumbotron "Claims" Doc.Empty

[<JavaScript>]
module UsersPage =
    let doc go =
        bsJumbotron "Users" Doc.Empty
```
Finally I consider the `NavBar` as its own module since it doesn't really depend on anything and nothing really depend on the `NavBar` as well. I define it this way:
```
[<JavaScript>]
module NavBarPage =
    let private makeNavlinks routerView go =
        routerView
        |> View.Map(fun currentPage ->
               [ ClientRoutes.Home; ClientRoutes.Claims; ClientRoutes.Users ]
               |> List.map
                      (fun page ->
                      liAttr [ if page = currentPage then yield attr.``class`` "active" ]
                          [ Doc.Link (string page) [] (fun _ -> go page) ] :> Doc)
               |> Doc.Concat)
        |> Doc.EmbedView

    let private logout go =
        li [ Doc.Link "Log out" [] (fun () ->
                 api.Logout()
                 go ClientRoutes.Login) ] :> Doc

    let doc routerView go = bsNav "admin portal" (makeNavlinks routerView go) (logout go)
```
I think now you can workout the `NavBarPage` code yourself as you pretty much know everything needed to understand it. We then end up with our code split in `Page modules`. Other than the pages, we also have our `ClientRoutes` module, `BootstrapUI` module and our `ApiClient` module which contains our code to interface with the REST api. Our webapp is then composed by nine modules including the `Client` module:
- ApiClient
- ClientRoutes
- BootstrapUI
- NavBarPage
- LoginPage
- HomePage
- ClaimsPage
- UsersPage
- Client

Great, we now have split our code nicely into modules. If we wanted to, we could put every module in different .fs file. Alright, I don't know about you but I am pretty happy with what we ended up with so let's put everything together and then conclude on what we have done today!

## Putting everything together

When putting everything together, I added a `Domain` module which contains the type that I deserialize from the REST api and I have included the code that we talked about [in the previous post](http://kimsereyblog.blogspot.sg/2015/08/computation-expression-approach-for.html). here is the complete code:

```
open System
open WebSharper

[<JavaScript>]
module Domain =
    type Claim = {
		id: string
		name: string
	}

    type Claims = Claim list

    type User = {
        id: string
        fullName: string
        emailAddress: Option<string>
        phoneNumber: Option<string>
        enabled: bool
        claims: Claims
    }

[<JavaScript>]
module Async =
    let map f xAsync = async { let! x = xAsync
                               return f x }
    let retn x = async { return x }

[<JavaScript>]
module AsyncApi =
    type ApiResult<'a> =
        | Success of 'a
        | Failure of ApiResponseException list

    and ApiResponseException =
        | Unauthorized of string
        | NotFound of string
        | UnsupportedMediaType of string
        | BadRequest of string
        | JsonDeserializeError of string
        override this.ToString() =
            match this with
            | ApiResponseException.Unauthorized err -> err
            | ApiResponseException.NotFound err -> err
            | ApiResponseException.UnsupportedMediaType err -> err
            | ApiResponseException.BadRequest err -> err
            | ApiResponseException.JsonDeserializeError err -> err

    let map f xAsyncApiResult =
        async {
            let! xApiResult = xAsyncApiResult
            match xApiResult with
            | Success x -> return Success(f x)
            | Failure err -> return Failure err
        }

    let retn x = async { return ApiResult.Success x }

    let apply fAsyncApiResult xAsyncApiResult =
        async {
            let! fApiResult = fAsyncApiResult
            let! xApiResult = xAsyncApiResult
            match fApiResult, xApiResult with
            | Success f, Success x -> return Success(f x)
            | Success f, Failure err -> return Failure err
            | Failure err, Success f -> return Failure err
            | Failure err1, Failure err2 -> return Failure(List.concat [ err1; err2 ])
        }

    let bind f xAsyncApiResult =
        async {
            let! xApiResult = xAsyncApiResult
            match xApiResult with
            | Success x -> return! f x
            | Failure err -> return (Failure err)
        }

    let start xAsyncApiRes =
        xAsyncApiRes
        |> Async.map (fun x -> ())
        |> Async.Start

    type ApiCallBuilder() =

        member this.Bind(x, f) =
            async {
                let! xApiResult = x
                match xApiResult with
                | Success x -> return! f x
                | Failure err -> return (Failure err)
            }
        member this.Return x = async { return ApiResult.Success x }
        member this.ReturnFrom x = x

    let apiCall = new ApiCallBuilder()

[<JavaScript>]
module ApiClient =
    open WebSharper.JavaScript
    open WebSharper.JQuery
    open AsyncApi
    open Claim
    open WebSharper.UI.Next

    type AuthToken =
        { Token : string
          Expiry : DateTime }
        member this.IsExpired() = DateTime.UtcNow - this.Expiry < TimeSpan.FromMinutes(10.0)

        static member Make token =
            { Token = token
              Expiry = DateTime.UtcNow }

        static member Default =
            { Token = ""
              Expiry = DateTime.UtcNow }

    type ValidToken =
        | ValidToken of string

    type Credentials =
        { Username : string
          Password : string }
        static member Default =
            { Username = "admin"
              Password = "admin" }

    type RequestSettings =
        { RequestType : JQuery.RequestType
          Url : string
          ContentType : string option
          Headers : (string * string) list option
          Data : string option }
        member this.toAjaxSettings ok ko =
            let settings =
                JQuery.AjaxSettings
                    (Url = "http://localhost/api/" + this.Url, Type = this.RequestType,
                     DataType = JQuery.DataType.Text, Success = (fun (result, _, _) -> ok (result :?> string)),
                     Error = (fun (jqXHR, _, _) -> ko (System.Exception(string jqXHR.Status))))

            this.Headers			|> Option.iter (fun h -> settings.Headers <- Object<string>(h |> Array.ofList))
            this.ContentType 	    |> Option.iter (fun c -> settings.ContentType <- c)
            this.Data 				|> Option.iter (fun d -> settings.Data <- d)
            settings

    type Api =
        { Login : Credentials -> Async<ApiResult<unit>>
          Logout : unit -> unit
          GetUsers : unit -> Async<ApiResult<User list>>
          GetClaims : unit -> Async<ApiResult<Claims>> }

    [<Literal>]
    let tokenStorageKey = "authtoken"

    let private ajaxCall (requestSettings : RequestSettings) =
        Async.FromContinuations <| fun (ok, ko, _) ->
            requestSettings.toAjaxSettings ok ko
            |> JQuery.Ajax
            |> ignore

    let private matchErrorStatusCode url code =
        match code with
        | "401" ->
            Failure
                [ ApiResponseException.Unauthorized
                  <| sprintf """"%s" - 401 The Authorization header did not pass security""" url ]
        | "404" -> Failure [ ApiResponseException.NotFound <| sprintf """"%s" - 404 Endpoint not found""" url ]
        | "415" ->
            Failure
                [ ApiResponseException.UnsupportedMediaType
                  <| sprintf """"%s" - 415 The request Content-Type is not supported/invalid""" url ]
        | code -> Failure [ ApiResponseException.BadRequest <| sprintf """"%s" - %s Bad request""" url code ]

    let private tryDeserialize deserialization input =
        try
            deserialization input |> ApiResult.Success
        with _ ->
            Failure [ ApiResponseException.JsonDeserializeError <| sprintf """"{%s}" cannot be deserialized""" input ]
        |> Async.retn

    let private getToken() =
        try
            JS.Window.LocalStorage.GetItem tokenStorageKey
            |> Json.Deserialize<AuthToken>
            |> ApiResult.Success
        with ex -> ApiResult.Failure [ Unauthorized "Unauthorized" ]
        |> Async.retn

    let private refreshToken (authToken : AuthToken) =
        async {
            let url = "auth/login/token/renew"
            if not (authToken.IsExpired()) then return ApiResult.Success authToken.Token
            else
                try
                    let! token = ajaxCall {
                                    RequestType = JQuery.RequestType.POST
                                    Url = url
                                    ContentType = None
                                    Headers = Some [ "Authorization", "Bearer " + authToken.Token ]
                                    Data = None }
                    return ApiResult.Success token
                with ex -> return matchErrorStatusCode url ex.Message
        }
        |> AsyncApi.bind (tryDeserialize Json.Deserialize<string>)
        |> AsyncApi.map (ValidToken)

    let private login credentials =
        async {
            let url = "auth/login/token"
            try
                let! token = ajaxCall {
                                RequestType = JQuery.RequestType.POST
                                Url = url
                                ContentType = Some "application/json"
                                Headers = None
                                Data = Some(Json.Serialize<Credentials>(credentials)) }
                return ApiResult.Success token
            with ex -> return matchErrorStatusCode url ex.Message
        }
        |> AsyncApi.bind (Json.Deserialize<string>
                          >> AuthToken.Make
                          |> tryDeserialize)
        |> AsyncApi.map (fun token -> JS.Window.LocalStorage.SetItem(tokenStorageKey, Json.Serialize<AuthToken>(token)))

    let private logout() = JS.Window.LocalStorage.RemoveItem(tokenStorageKey)

    let private getClaims (ValidToken token) =
        async {
            let url = "auth/claims"
            try
                let! claims = ajaxCall {
                                RequestType = JQuery.RequestType.GET
                                Url = url
                                ContentType = None
                                Headers = Some [ "Authorization", "Bearer " + token ]
                                Data = None
                            }
                return ApiResult.Success(claims)
            with ex -> return matchErrorStatusCode url ex.Message
        }
        |> AsyncApi.bind (tryDeserialize Json.Deserialize<Claims>)

    let private getUsers (ValidToken token) =
        async {
            let url = "users"
            try
                let! users = ajaxCall {
                                RequestType = JQuery.RequestType.GET
                                Url = url
                                ContentType = None
                                Headers = Some [ "Authorization", "Bearer " + token ]
                                Data = None
                            }
                return ApiResult.Success users
            with ex -> return matchErrorStatusCode url ex.Message
        }
        |> AsyncApi.bind (tryDeserialize Json.Deserialize<User list>)

    let api =
        { Login = login
          Logout = logout
          GetUsers = fun () -> apiCall {
									let! token = getToken()
									let! validToken = refreshToken token
									return! getUsers validToken
								}
          GetClaims = fun () -> apiCall {
									let! token = getToken()
									let! validToken = refreshToken token
									return! getClaims validToken
								} }

[<JavaScript>]
module BootstrapUI =
    open WebSharper.UI.Next
    open WebSharper.UI.Next.Html
    open WebSharper.UI.Next.Client

    module Button =
        type private ButtonColor =
            | Default
            | Primary

        type private ButtonStyle =
            | FullWidth
            | Inline

        let private makeButton txt btnColor btnStyle action =
            let classes =
                [ yield "btn"
                  yield match btnColor with
                        | Default -> "btn-default"
                        | Primary -> "btn-primary"
                  yield match btnStyle with
                        | FullWidth -> "full"
                        | Inline -> "inline" ]
                |> String.concat (" ")
            Doc.Button <| txt <| [ attr.``class`` classes
                                   attr.``type`` "submit" ]
            <| action

        let bsBtnDefaultInline txt action =
			makeButton txt ButtonColor.Default ButtonStyle.Inline action

        let bsBtnDefaultFull txt action =
			makeButton txt ButtonColor.Default ButtonStyle.FullWidth action

        let bsBtnPrimaryInline txt action =
			makeButton txt ButtonColor.Primary ButtonStyle.Inline action

        let bsBtnPrimaryFull txt action =
			makeButton txt ButtonColor.Primary ButtonStyle.FullWidth action

    let bsNav brand leftLinks rightLinks =
        let navHeader =
            divAttr [ attr.``class`` "navbar-header" ]
                    [ buttonAttr [ attr.``class`` "navbar-toggle collapsed"
                                   Attr.Create "data-toggle" "collapse"
                                   Attr.Create "data-target" "#menu"
                                   Attr.Create "aria-expanded" "false" ]
                                 [ spanAttr [ attr.``class`` "sr-only" ] []
                                   spanAttr [ attr.``class`` "icon-bar" ] []
                                   spanAttr [ attr.``class`` "icon-bar" ] []
                                   spanAttr [ attr.``class`` "icon-bar" ] [] ]
                     aAttr [ attr.``class`` "navbar-brand title"
                             attr.href "#" ] [ text brand ] ]

        let navMenu =
            divAttr [ attr.``class`` "collapse navbar-collapse"
                      attr.id "menu" ]
                    [ ulAttr [ attr.``class`` "nav navbar-nav" ] [ leftLinks ]
                      ulAttr [ attr.``class`` "nav navbar-nav navbar-right" ]
                             [ rightLinks ] ]

        navAttr [ attr.``class`` "navbar navbar-default" ]
            [ divAttr [ attr.``class`` "container-fluid" ]
                      [ navHeader; navMenu ] ] :> Doc

    let bsInput placeHolder rvTxt =
        Doc.Input [ attr.``class`` "form-control"
                    attr.placeholder placeHolder ] rvTxt

    let bsPasswordInput placeHolder rvPwd =
        Doc.PasswordBox [ attr.``class`` "form-control"
                          attr.placeholder placeHolder ] rvPwd

    let bsPanelDefault body =
        divAttr [ attr.``class`` "panel panel-default" ] [ divAttr [ attr.``class`` "panel-body" ] body ]

    let bsPanelDefaultWithTitle title body =
        divAttr [ attr.``class`` "panel panel-default" ]
                [ divAttr [ attr.``class`` "panel-heading" ]
                          [ h3Attr  [ attr.``class`` "panel-title" ]
                                    [ text title ] ]
                  divAttr [ attr.``class`` "panel-body" ] body ]

    let bsAlertDanger message =
        divAttr [ attr.``class`` "alert alert-danger"
                  Attr.Create "role" "alert" ] [ text message ] :> Doc

    let bsRow bsCol = divAttr [ attr.``class`` "row" ] bsCol

    let bsCol3 body = divAttr [ attr.``class`` "col-md-3" ] body

    let bsCol4 body = divAttr [ attr.``class`` "col-md-4" ] body

    let bsContainer body = divAttr [ attr.``class`` "container" ] body

    let bsJumbotron title body =
        divAttr [ attr.``class`` "jumbotron" ]
                [ divAttr [ attr.``class`` "container" ]
                          [ h1 [ text title ] body ] ]

[<JavaScript>]
module ClientRoutes =
    open WebSharper.UI.Next

    type Page =
        | Home
        | Claims
        | Users
        | Login
        override this.ToString() =
            match this with
            | Home -> "Home"
            | Claims -> "Claims"
            | Users -> "Users"
            | Login -> "Login"

    let private map =
        function
        | Home -> []
        | Claims -> [ "claims" ]
        | Users -> [ "users" ]
        | Login -> [ "login" ]

    let private reverMap =
        function
        | [] -> Home
        | [ "home" ] -> Home
        | [ "claims" ] -> Claims
        | [ "users" ] -> Users
        | [ "login" ] -> Login
        | _ -> failwith "404"

    let install () =
        RouteMap.Create map reverMap
        |> RouteMap.Install

[<JavaScript>]
module NavBarPage =
    open WebSharper.UI.Next
    open WebSharper.UI.Next.Html
    open WebSharper.UI.Next.Client
    open BootstrapUI
    open ApiClient

    let private makeNavlinks routerView go =
        routerView
        |> View.Map(fun currentPage ->
               [ ClientRoutes.Home; ClientRoutes.Claims; ClientRoutes.Users ]
               |> List.map
                      (fun page ->
                      liAttr [ if page = currentPage then yield attr.``class`` "active" ]
                             [ Doc.Link (string page) [] (fun _ -> go page) ] :> Doc)
               |> Doc.Concat)
        |> Doc.EmbedView

    let private logout go =
        li [ Doc.Link "Log out" [] (fun () ->
                                     api.Logout()
                                     go ClientRoutes.Login) ] :> Doc

    let doc routerView go = bsNav "admin portal" (makeNavlinks routerView go) (logout go)


[<JavaScript>]
module LoginPage =
    open BootstrapUI
    open WebSharper.UI.Next
    open WebSharper.UI.Next.Html
    open WebSharper.UI.Next.Client
    open ApiClient

    let private login rvUsername rvPassword rvLoginError go () =
        async {
            let! login = api.Login { Username = Var.Get rvUsername
                                     Password = Var.Get rvPassword }
            match login with
            | AsyncApi.Failure err ->
                Var.Set rvLoginError
						"You may have keyed in an invalid Username or Password. Please try again."
                api.Logout()
            | _ -> ()
            return login
        }
        |> AsyncApi.map (fun _ -> go ClientRoutes.Home)
        |> AsyncApi.start

    let doc go =
        let rvUsername = Var.Create ""
        let rvPassword = Var.Create ""
        let rvErr = Var.Create ""

        let nameInput = bsInput "Username" rvUsername
        let pwdInput = bsPasswordInput "Password" rvPassword
        let errDiv = rvErr.View
                     |> View.Map(fun err -> 	if err = "" then Doc.Empty
												else bsAlertDanger err)
                     |> Doc.EmbedView

        let buttons =
            bsPanelDefault
                [ form [ errDiv
                         nameInput
                         pwdInput
                         Button.bsBtnDefaultFull "Log in"
												 (login rvUsername rvPassword rvErr go) ] ]
        bsRow [ bsCol4 [ Doc.Empty ]
                bsCol4 [ h1Attr [attr.``class`` "title"]
								[text "admin portal"]
						 buttons ]
                bsCol4 [ Doc.Empty ] ]


[<JavaScript>]
module HomePage =
    open WebSharper.UI.Next
    open WebSharper.UI.Next.Html
    open WebSharper.UI.Next.Client
    open BootstrapUI

    let doc go =
        bsJumbotron "Hello,"
                    ([p [text "Welcome to the admin portal v1.0."] :> Doc
                      Button.bsBtnPrimaryInline "View claims"
												(fun () -> go ClientRoutes.Claims) :> Doc
                      Button.bsBtnPrimaryInline "View users"
												(fun () -> go ClientRoutes.Users) :> Doc]
                     |> Doc.Concat)

[<JavaScript>]
module ClaimsPage =
    open WebSharper.UI.Next
    open WebSharper.UI.Next.Html
    open WebSharper.UI.Next.Client
    open BootstrapUI

    let doc go =
        bsJumbotron "Claims" Doc.Empty

[<JavaScript>]
module UsersPage =
    open WebSharper.UI.Next
    open WebSharper.UI.Next.Html
    open WebSharper.UI.Next.Client
    open BootstrapUI

    let doc go =
        bsJumbotron "Users" Doc.Empty

[<JavaScript>]
module Client =
    open WebSharper.UI.Next
    open WebSharper.UI.Next.Html
    open WebSharper.UI.Next.Client
    open BootstrapUI

    let Main =
        let router = ClientRoutes.install()

        let doc =
            router.View
            |> View.Map(fun page ->
                   let go = Var.Set router

                   let addNavBar body =
                       [ NavBarPage.doc router.View go
                         body ]
                       |> Doc.Concat

                   let embedInContainer body = bsContainer [ body ]

                   match page with
                   | ClientRoutes.Login ->
                       LoginPage.doc go
                       |> embedInContainer :> Doc
                   | ClientRoutes.Home ->
                       HomePage.doc go
                       |> embedInContainer
                       |> addNavBar
                   | ClientRoutes.Claims ->
                       ClaimsPage.doc go
                       |> embedInContainer
                       |> addNavBar
                   | ClientRoutes.Users ->
                       UsersPage.doc go
                       |> embedInContainer
                       |> addNavBar)
            |> Doc.EmbedView

        Doc.RunById "main" doc
```
This is the full F# code resulting in the gif demo that I showed in the beginning of the post. I feel that the code is pretty straight forward and can easily be read. I am sure it can be simplified but I wanted to show you how easily it is to understand what each part does, isn't it nice? Well great job! we are done for today so let's conclude on what we've seen.

# Conclusion
Last week we saw [how to handle REST api calls from a frontend WebSharper app](http://kimsereyblog.blogspot.sg/2015/08/computation-expression-approach-for.html). Today we looked in more details on how to create a single page application (`SPA`) using `WebSharper UI.Next`. We saw how to build HTML using `UI.Next` function and how to apply its reactive concept with `Var`s and `View`s. We also saw how we could overcome routing using `UI.Next router` and `routeMap` which is part of the big issues with `SPA`. We then finished by looking at how we could seperate our codebase into modules and make it more granular. Of course those are just the basics of what a `SPA` is supposed to do but at least [we've got started!](https://en.wiktionary.org/wiki/a_journey_of_a_thousand_miles_begins_with_a_single_step) Like I said previously, I am far from being an expert and writing this post is a way to improve myself and understand what I am doing. So if you have any suggestion, hit me on twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam) or in the comment section! Thanks for reading!
