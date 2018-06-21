# Basic Authentication with Nginx

Basic authentication provides an easy way to password protect an endpoint on our server. Today we will see how we can create a password file and use it to enable basic authentication on Nginx.

1. Create a password
2. Enable basic authentication
3. Reuse configuration

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

Now if we navigate to `/etc/myapp/` we will be able to find our `.htpasswd` file containing encrypted passwords together with usernames.

## 2. Enable basic authentication

Enabling basic authentication can be achieved by using the `auth_basic` and `auth_basic_user_file` directives.

```json
...
```

The `auth_basic` defines the realm where the basic auth operates. Now when we navigate to the location, we should be prompted with the basic auth dialog box.

To add another layer of security, we can use `allow x.x.x.x` and `deny x.x.x.x` to restrict access to only certain ip addresses.

```json
satisfy all
allow x.x.x.x;
deny all;

auth...
```

## 3. Reuse configuration

In order to reuse the configuration we can extract it and put it in a `auth_basic` file and `ip_access` file under `/etc/nginx/conf.d`.

We would create `/etc/nginx/conf.d/basic_auth`:

```json
auth..
```

And under `/etc/nginx/conf.d/ip_access`:

```json
allow x.x.x.x;
deny all;
```

And we would use it with the `include` directive:

```
location /test {
    include conf.d/basic_auth;
    include conf.d/ip_access;
}
```

And this concludes today's post for basic authentication with Nginx.

## Conclusion

Today we saw how to enable basic authentication for nginx using htpasswd. We saw how to configure the basic auth using the `auth_basic` and `auth_basic_user_file` directives and saw how to restrict access by IP to add a second layer of security. Lastly we saw how we could move the configuration to separate reusable configuration files which can be reused using the `include` directive. Hope you liked this post, see you next time!
