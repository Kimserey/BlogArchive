# Let's Encrypt for ASP.NET Core application on IIS

Few weeks ago we saw how we could generate a SSL cert for free using a browser based ACME implementation. While doing that, we had some manual process to do for the verification to happen, either by changing the DNS settings or making a key available on an endpoint. Today we will see how we can achieve that without manual handling of the secrets.

1. Register application on IIS
2. Download Let's Encrypt and configure

## 1. Register application on IIS

Coming from an empty Windows Server 2016 instance, we can start by installing IIS by activating from .............

ASP.NET Core runs with Kestrel. To be able to manage the Kestrel process, we then install the ASP.NET Core module.

....

Kestrel is a lightweight webserver. It needs to be placed behind a reverse proxy like Apache, nginx or IIS. One of the reason why is that only one application can listen to the HTTP port at a time on a machine therefore IIS can act as a reverse proxy and redirect to all Kestrel processes within the machine. Another point is that IIS can terminate SSL communication and as we will see here, it is possible to install an ACME implementation on IIS to automate the NS verification and automatically configure SSL.

Now that we have IIS setup with the module setup, we can copy our dll's on the machine and create a website in IIS console to point to the folder.

To host multiple services, we can download the URL rewrite module. This will also be needed to redirect HTTP calls to our HTTPS endpoint.

Once this done, we should be able to access our process from internet.

## 2. Use Let's Encrypt

When we navigate to our website we see that it is insecure.

In order to provide a valid cert for our SSL, we need an implementation of the ACME protocol.
The easiest way is to get the PowerShell module from ACMESharp.

https://github.com/ebekker/ACMESharp

Once installed, we can configure automatically our SSL cert.