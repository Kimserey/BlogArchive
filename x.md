# Deploy your WebSharper selfhosted web app easily

Last week I talked about how I used an OCR library to create a web app which reads text from an image.
I explained the whole process of creating it but I didn't explain how I deployed it to Azure.
I thought that since I asked myself the question, other developers might have wondered as well.

__What are the steps to deploy a selfhost?__

Today I will explain the steps that I took to deploy [https://arche.cloudapp.net:9000](https://arche.cloudapp.net:9000)

## 1. Create default template websharper client server webhost

Go on github find the new release of WebSharper and get the vsix.

[https://github.com/intellifactory/websharper/releases](https://github.com/intellifactory/websharper/releases)

![where to get websharper wsix](https://4.bp.blogspot.com/-D8sPvjtYs78/VzQ2rLM0sHI/AAAAAAAAAIM/6o-XtdZTJZQcRYJflw_zGCxSnbRsTDZAwCLcB/s200/download_vsix.png)

Install it and you will have access to all Websharper templates.

Create a default Selfhost client server application and run it.
If everything works well you should have a running webapp.

## 2. Bind to all interfaces

When you created from the projet template, you should have an entrypoint which looks like this:

```
module SelfHostedServer =

    open global.Owin
    open Microsoft.Owin.Hosting
    open Microsoft.Owin.StaticFiles
    open Microsoft.Owin.FileSystems
    open WebSharper.Owin

    [<EntryPoint>]
    let Main args =
        let rootDirectory, url =
            match args with
            | [| rootDirectory; url |] -> rootDirectory, url
            | [| url |] -> "..", url
            | [| |] -> "..", "http://localhost:9000/"
            | _ -> eprintfn "Usage: test ROOT_DIRECTORY URL"; exit 1
        use server = WebApp.Start(url, fun appB ->
            appB.UseStaticFiles(
                    StaticFileOptions(
                        FileSystem = PhysicalFileSystem(rootDirectory)))
                .UseSitelet(rootDirectory, Site.Main)
            |> ignore)
        stdout.WriteLine("Serving {0}", url)
        stdin.ReadLine() |> ignore
        0
```

This code will start a OWIN selfhost hosted on `http://localhost:9000/` if you don't provide any arguments while launching the `.exe`.
It only binds to your localhost.
In order to make it available, you must bind it to all interfaces.
To do so, replace `localhost` by `+`.
```
let rootDirectory, url = "..", "http://+:9600/"
```
Now of you try to run the webapp, it will crash unless you started visual studio as administrator.

Either you can choose to always run as admin or you can reserve this url for your user account.
This can be done by adding a urlacl.

## 3. Add urlacl (optional)

```
netsh http 
add urlacl url="http://+:9600" user="username"
```
To find what is your full username you can use `whoami` from the cmd prompt.
And you can view your urlacl already added by typing `show urlacl`.

Build your app and find the `.exe` in your `bin` folder and you should be able to run it and it should launch the webapp.
At this point, we have the web app ready for deployment.

## 4. Deploy to Azure

Go to the azure portal and select create VM.

![create vm on azure](https://2.bp.blogspot.com/-lzB8Yob4ZbM/VzQ7fui6XoI/AAAAAAAAAI0/lmn-LU682icjFX1MxVk80MbSSma4H7OmQCKgB/s1600/create_vm.png)

Once created, RDP into the VM and copy the binaries into a folder and run the executable.

At the moment in the Azure portal, the RDP button looks like this:

![rdp button](https://2.bp.blogspot.com/-_I2WKGGlQV0/VzQ7pSGi-lI/AAAAAAAAAIc/eWaRpQB_sEwsESFqreeREiH8xlxMv5iBACKgB/s200/Screen%2BShot%2B2016-05-12%2Bat%2B09.15.26.png)

Copy the following file into a folder on your VM:

![binaries](https://3.bp.blogspot.com/-7A79NqUDGjQ/VzQ7sf3KR1I/AAAAAAAAAIg/GVmBCQvOr6cKVTPj87iEXf61OeiD7d9jQCKgB/s1600/file_copy.png)

It should run without issue but __it will not be accessible from outside the VM yet__.

We need to open the inbound port on your firewall to let others access this endpoint.

![inbound port](https://3.bp.blogspot.com/-gLCSqup1A3g/VzQ7vQ_5LkI/AAAAAAAAAIk/HBrwUqXYDKgkznuUlzB55OQHSGbLxbI0QCKgB/s1600/inbound.png)
![inbound port opening](https://4.bp.blogspot.com/-HKJonRQFoQE/VzQ8-iW1syI/AAAAAAAAAJA/oOScdedJa6I2uuC2almJd7D5lDu7CPsmwCLcB/s1600/firewall_ports.png)

The last step is to tell Azure about your public endpoint. 
This is set from the Azure portal, find the settings of your VM and add the endpoint `9600`.

![azure endpoints](https://4.bp.blogspot.com/-y_PNUKQHaDo/VzQ707rkqkI/AAAAAAAAAI4/0fx8dVxLTRoJ2Wizm1eocH0lDpUfhjusQCKgB/s320/azure_endpoints.png)

Now your webapp should be accessible from anywhere on the internet.
Congratulation you have deployed your WebSharper selfhosted webapp!

![working app](https://4.bp.blogspot.com/-bUukM6wcVHQ/VzQ9yln5VkI/AAAAAAAAAJI/FM90Du-uCcg0bm7w4AwWq-wTQwFoKcSAwCLcB/s1600/working_app.png)

## Conclusion

Today we saw how we could deploy a web app built with WebSharper easily.
It might have felt like a lot of steps but the whole process only takes few minutes.
All you need to remember is to __open the port on the firewall__ and __specify the port on Azure settings__.
For web apps which handle a small amount of users, a selfhost is a very good approach as it is easy and
cost efficient to have a single VM hosting multiple selfhosted web apps.
By showing you this I hope it completed the whole picture from developping to deploying web apps.
Let me know if you deploy some amazing web apps! If you have any comments, hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).
See you next time!
