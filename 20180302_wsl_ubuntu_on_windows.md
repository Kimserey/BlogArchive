# Install dotnet on Ubuntu with the Linux subsystem on Windows 10

Dotnet and ASP NET Core are rapidly moving toward cross platform development. As of today, we are already able to write dotnet application running on Windows, Linux or docker. But when our development environment differs from our production environment, for example using Windows for development while deploying on Ubuntu, it can be hard to catch problems early. What we can do is spin off a virtual machine which we can use to test our application for development pruposes. Recently a new approach came to life thanks to Windows subsystems which allows us to run a Linux binaries executables natively on Windows 10. Today we will explore how we can run a Hello World ASP NET Core application locally on Ubuntu on Windows 10. This post will be composed by three parts:

1. Install Linux subsystem on Windows 10
2. Install dotnet on Ubuntu
3. Run an ASP NET Core behind nginx

## 1. Install Linux subsystem on Windows 10

Start by enabling WSL via PowerShell:

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

Alternatively we can also enable WSL from the Windows Features.

![WSL](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20180302_wsl/WSL.PNG)

Then download Ubuntu from the Microsoft Store.

![MSFT_Store](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20180302_wsl/msft_store.PNG)

After the download complete, launch it and we will be prompted to create our root user. Once done, we should be able to open the Ubuntu shell.

## 2. Install dotnet on Ubuntu

Now that we have a subsystem, we can start replicating what would be necessary on the remote server.
The first SDK which we will need is `dotnet`.

Installing `dotnet` consists of three steps; installing the public key of microsoft packages into the trusted keys, adding the repository for `apt-get` and lastly downloading `dotnet` with `apt-get`.

All the steps are available on `dotnet` documentation [https://docs.microsoft.com/en-us/dotnet/core/linux-prerequisites?tabs=netcore2x](https://docs.microsoft.com/en-us/dotnet/core/linux-prerequisites?tabs=netcore2x) but I will try to provide more information.

The first step is to get the public key for microsoft packages and place it into the trusted public keys by `apt`. This is meant to tell `apt` to trust the microsoft repository hence therefore inform `apt` that we trust the packages downloaded from the repository.

```bash
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
```

Next we need to actually configure the repository by providing the address of the packages. Then we use `update` to update the list of packages on `apt`.

```bash
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod xenial main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-get update
```

Once all done, we can install the `dotnet` SDK.

```bash
sudo apt-get install dotnet-sdk-2.1.4
```

## 3. Run an ASP NET Core behind nginx

For a simple Hello World application, we create an empty template of ASP NET Core application called `HelloWorld` and run `dotnet publish -c Release` to publish it.

Next from the Ubuntu shell, we copy the binaries into `/var/aspnetcore/hello-world/`.

```bash
cp -r [path of publish folder] /var/aspnetcore/hello-world
```

And verify that we can run the application using `dotnet HelloWorld.dll`.

We can also make sure that we can hit the endpoint from the browser by going to `http://localhost:5000`.
Kestrel allows us to selfhost our application and if we hit the port, we can access the application. But it is not recommended to direclty hit Kestrel, instead it is best to pass by a reverse proxy like Nginx giving us more power in term of response, caching and of course act as a reverse proxy.

### Install Nginx

Similarly as we installed dotnet, we can install nginx and start it.

```bash
sudo apt-get install nginx
```

Then we can start nginx.

```bash
sudo service nginx start
```

The configuration of nginx can be found in `/etc/nginx/sites-available/default`. Change the content of the file by the following:

```txt
server {
    listen 80;
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $http_host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Next we should be able to navigate to `http://localhost` and see our application.

_To run Kestrel as a daemon, dotnet documentation recommends to use `systemd`. Unfortunately I did not manage to get it running on WSL. Multiple issues are open on the WSL repository on GitHub._

The official documentation can be found [here](https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/linux-nginx?tabs=aspnetcore2x).

That concludes today post on running a Hello World ASP NET Core application locally on Ubuntu on Windows 10.

## Conclusion

Today we discovered how to install Ubuntu as a subsystem within Windows 10. Installing a Linux system gives us access to the powerful functionalities of bash. We then saw how to install dotnet on Ubuntu and how we could boot a Hello World application behind Nginx. Hope you liked this post. See you next time!