# Nginx Passing request to underlying process with location and proxy_pass

When writing 

```
location /api0 {
    proxy_pass http://localhost:5000;
}
```

Becomes /api0/home

```txt
location /api1/ {
    proxy_pass http://localhost:5000;
}
```

Becomes /api0/home

```
location /api2 {
    proxy_pass http://localhost:5000/;
}
```

Becomes //home

```
location /api3/ {
    proxy_pass http://localhost:5000/;
}
```

Becomes /home OK

```
location /api4 {
    proxy_pass http://localhost:5000/test;
}
```

Becomes /test/home OK

```
location /api5/ {
    proxy_pass http://localhost:5000/test;
}
```

Becomes /testhome

``` 
location /api6 {
    proxy_pass http://localhost:5000/test/;
}
```

Becomes /test//home

```
location /api7/ {
    proxy_pass http://localhost:5000/test/;
}
```

Becomes /test/home OK