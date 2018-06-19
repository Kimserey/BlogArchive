# Nginx Passing request to underlying process with location and proxy_pass

Few weeks ago we saw how we could [Host ASP NET Core application behind Nginx](https://kimsereyblog.blogspot.com/2018/06/asp-net-core-with-nginx.html). We saw that Kestrel works as a selfhost webserver and in order to get request forwarded to it, we need to proxy them in Nginx using the `location` and `proxy_pass` directives. Today we will see the details of the path handling when using `proxy_pass` by first looking at the URI rule of Nginx and secondly by looking into some examples.

1. The URI rule
2. Examples

## 1. The URI rule

The rule of Nginx is that __if the proxy_pass URL contains a URI, the matched path will be replaced by the `proxy_pass` URL.__

The URI is what comes after the host __including a trailing slash__. Meaning that `http://localhost:5000` does not have a URI but `http://localhost:5000/` has a URI which is `/`. This is important to understand as it has an implication on the behavior of Nginx.

If no URI is specified, the full path is forwarded and nothing is replaced.

## 2. Examples

Now let's assume that we have setup an ASP NET Core application running on `http://locahost:5000` and has two endpoint `/home` and `/test/home` which respectively are accessible on `http://localhost:5000/home` and `http://localhost:5000/test/home`. __And let's assume that we want to be able to proxy all calls to `/api/xxx` to our ASP NET Core application.__

Now we saw in 1) that if there is no URI, the full path is forwarded, this means that ......

```
location /api {
    proxy_pass http://localhost:5000;
}
```

Becomes /api/home

```txt
location /api/ {
    proxy_pass http://localhost:5000;
}
```

Becomes /api/home

```
location /api {
    proxy_pass http://localhost:5000/;
}
```

Becomes //home

```
location /api/ {
    proxy_pass http://localhost:5000/;
}
```

Becomes /home OK

```
location /api {
    proxy_pass http://localhost:5000/test;
}
```

Becomes /test/home OK

```
location /api/ {
    proxy_pass http://localhost:5000/test;
}
```

Becomes /testhome

``` 
location /api {
    proxy_pass http://localhost:5000/test/;
}
```

Becomes /test//home

```
location /api/ {
    proxy_pass http://localhost:5000/test/;
}
```

Becomes /test/home OK