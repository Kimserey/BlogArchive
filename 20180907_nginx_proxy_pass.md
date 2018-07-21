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

Now we saw in 1) that if there is no URI, the full path is forwarded, this means that in our example, any `proxy_pass` specified without URI will not work. For example, the following configurations will not work:

```
location /api {
    proxy_pass http://localhost:5000;
}
```

Notice that the `proxy_pass` URL does not contain any URI therefore if we hit `myserver/api/home`, it will be forwarded as `http://localhost:5000/api/home` which does not exists.

```txt
location /api/ {
    proxy_pass http://localhost:5000;
}
```

Similarly here, it will be forwarded as `http://localhost:5000/api/home` which does not exists.
Now if we add a URI, the matched path will be replaced so the following will work:

```
location /api/ {
    proxy_pass http://localhost:5000/;
}
```

`/` is the URI, so the path will be replaced. Here the path is `/api/` so for `myserver/api/home`, `myserver/api/` will be replaced by `http://localhost:5000/` which results in `http://localhost:5000/home` which works!
But we still need to be cautious as the following will not work:

```
location /api {
    proxy_pass http://localhost:5000/;
}
```

Note that the location path does not contain a trailing slash therefore `mysever/api/home` will result in `http://localhost:5000//home` which does not exists.

And this works the same when the URI is `/test`:

```
location /api {
    proxy_pass http://localhost:5000/test;
}
```

This will work as it will `/api/home` will be proxied to `/test/home`.

```
location /api/ {
    proxy_pass http://localhost:5000/test/;
}
```

This will also work as `/api/home` will be proxied to `/test/home`.

```
location /api/ {
    proxy_pass http://localhost:5000/test;
}
```

This will not work as `/api/home` will result in `/testhome`, missing the slash.

``` 
location /api {
    proxy_pass http://localhost:5000/test/;
}
```

This will not work as `/api/home` will result in `/test//home`.

## Conclusion

Today we explored different combinations between `location` path and `proxy_pass` URL and saw which were working as expected. More importantly we saw the rule were __when a URI is present in `proxy_pass`, the matched path is replaced where an empty trailing slash is considered as a URI__. Following this rule, it should allow us to understand if a request will match what we expect or not. Hope you liked this post, see you next time!