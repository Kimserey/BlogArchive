# Inspect proxied requests ffrom Nginx to Kestrel

In previous blog posts, we saw [how to proxy requests to an ASP NET Core application using Nginx](https://kimsereyblog.blogspot.com/2018/06/asp-net-core-with-nginx.html). We saw that request headers also can be proxied with `proxy_set_header` In order to ease development, we need to be able to debug the values to verify that they are what we expect.
Today we will see two methods to inspect the proxied requests. This post will be composed by two parts:

1. Nginx location routing
2. Nginx variable debugging
3. Mitmproxy

## 1 Nginx location routing

Considering the following configuration of our server:

```txt
server {
    listen 80;

    location / {
        proxy_pass http://localhost:5000; 
    }

    location /api/ {
        proxy_pass http://localhost:5001/; 
    }
}
```

If we want to check whether our location routes are properly configured, we can short circuit the proxy_pass with `return` and use `curl` to check whether the location is properly selected.

```txt
server {
    listen 80;

    location / {
        return 200 "location '/'";
        proxy_pass http://localhost:5000; 
    }

    location /api/ {
        return 200 "location '/api/'";
        proxy_pass http://localhost:5001/; 
    }
}
```

When we use `curl`, we can check wheter our locations are hit as expected.

```txt
> curl http://localhost/test
location '/'

> curl http://localhost/api/test
location '/api/'
```

## 2. Nginx variable debugging

[http://nginx.org/en/docs/varindex.html](http://nginx.org/en/docs/varindex.html)

Nginx also provides a set of variable which can be found in the [documentation](http://nginx.org/en/docs/varindex.html). Some of the common ones are `$host`, `$request_uri` or `$scheme`.

To check the values of those variables at runtime, we can use the same `return` method as in 1) by adding the token in the text.

```txt
location / {
    return 200 "location '/' $scheme $host $request_uri $uri";
}
```

Then using `curl`:

```txt
> curl localhost/test
location '/' http localhost /test /test
```

## 3. Mitmproxy

