# Let's Encrypt for ASP.NET Core application on IIS

Few weeks ago we saw how we could generate a SSL cert for free using a browser based ACME implementation. While doing that, we had some manual process to do for the verification to happen, either by changing the DNS settings or making a key available on an endpoint. Today we will see how we can achieve that without manual handling of the secrets.

1. Register application on IIS
2. Use Let's Encrypt

## 1. Register application on IIS

Coming from an empty Windows Server 2016 instance, we can start by installing IIS by activating from __Add Roles And Features__ from __Manage__ on the __Server Manager__.

ASP.NET Core runs with Kestrel. To be able to manage the Kestrel process, we then install the ASP.NET Core module. https://github.com/dotnet/core/blob/master/release-notes/download-archives/2.0.6-download.md#windows

Kestrel is a lightweight webserver. It needs to be placed behind a reverse proxy like Apache, nginx or IIS. One of the reason why is that only one application can listen to the HTTP port at a time on a machine therefore IIS can act as a reverse proxy and redirect to all Kestrel processes within the machine. Another point is that IIS can terminate SSL communication and as we will see here, it is possible to install an ACME implementation on IIS to automate the NS verification and automatically configure SSL.

Now that we have IIS setup with the module setup, we can copy our dll's on the machine and create a website in IIS console to point to the folder. On the application pool, make sure to specify __No Managed code__ for the .NET CLR version as ASP.NET Core is not managed by IIS, it runs as a separate process.

Once this done, we should be able to access our process from internet.

## 2. Use Let's Encrypt

When we navigate to our website we see that it is insecure.

In order to provide a valid cert for our SSL, we need an implementation of the ACME protocol.
The easiest way is to get the ACME CLI win-acme.

https://github.com/PKISharp/win-acme

Once downloaded, place it somewhere on the VM and add it to the path. Then simply run `letsencrypt` and you will be prompted with the menu. Follow the instruction and the CLI will verify that you own the domain and setup your SSL automatically.

![win-acme](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20180324/letsencrypt.PNG)

To host multiple services, we can download the URL rewrite module. This will also be needed to redirect HTTP calls to our HTTPS endpoint.

https://www.iis.net/downloads/microsoft/url-rewrite

To redirect HTTP to HTTPS, we configure the following:

![config]()

The condition `{HTTPS}` with pattern `OFF` means that we detect when HTTPS is OFF. Once detected we redirect to HTTPS using the pattern `https://{HTTP_HOST}/{R:1}`.

![rediredct]()

## Conclusion

Today we saw how we could quickly get an ASP.NET Core application hosted on a Windows Server VM behind IIS. We also saw how we could issue a SSL cert using an automated verification of domain with ACME protocol and Let's Encrypt. Hope you like this post, see you next time!