# Manage configurations with ASP NET Core on Ubuntu

Managing configurations can be challenging. We cannot simply check-in in our repository secrets and connection strings and at the same time we want an easy way to maintain them.
Today we will see how we can manage secrets is am easy way on Ubuntu with systemd.

1. Make secrets available on server with systemd
2. Manage secrets locally with UserSecrets on ASP NET Core
3. Manage UserSecrets for dotnet Console Application

## 1. Objective

We need to keep secrets out of the source code. Therefore we want to have our application get secrets locally for local testing and we want the application to get them in our hosted environment.
In order to achieve that we will use systemd override configuration to hold configuration of secrets on our server and in our local machine we will use UserSecrets which holds configurations in the user app folder.

*Take note that UserSecrets file is not encrypted. The only protection we get is the OS user protection.*

## 1. Make secrets available on server with systemd

```sh
systemctl edit /etc/systemd/system/myapp.service
```

```sh
[Service]
Environment=ASPNETCORE_ENVIRONMENT=production
Environment=MY_VAR=secret
```

## 2. Manage secrets locally with UserSecrets on ASP NET Core

Right click on application, manage user secret.
Or use CLI secret to add list secret
File is located in app data user
When run the secrets are injected as configuration provider by default in the web builder (find in aspnetcore)

## 3. Manage UserSecrets for dotnet Console Application

Add the cli
Add directly the folder and reference to the secret
Add the library secret and register in the configuration the user secret provider.
The configuration will now be available.