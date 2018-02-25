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

![WSL](WSL.png)

Then download Ubuntu from the Microsoft Store.

![MSFT_Store]()

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

