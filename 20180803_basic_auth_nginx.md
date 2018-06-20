# Basic Authentication with Nginx

Basic authentication provides an easy way to password protect an endpoint on our server. Today we will see how we can create a password file and use it to enable basic authentication on Nginx.

1. Create a password
2. Enable basic authentication

## 1. Create a password

To create a password, we will use the `apache2-utils` tool called `htpasswd`.

```
sudo apt-get update
sudo apt-get install apache2-utils
```

`htpasswd` allows use to create passwords encrypted stored in a file

```
sudo htpasswd -c /etc/myapp/.htpasswd user1
```

`-c` is used to create the file. If we want to add other users we can omit the parameter.

```
sudo htpasswd /etc/myapp/.htpasswd user2
```
