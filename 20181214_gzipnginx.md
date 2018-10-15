# Enable gzip on Nginx

Compression static files before serving them can be very beneficial in scenarios like frontend development and SPA where we send an entire application in the form of a JS file. Today we will see how we can enable gzip compression on Nginx.

1. Example
2. Enable gzip
3. Extra - test nginx from Windows with Docker container

## 1. Example

Let's take for example a website composed by 3 files:

```
/index.html
/bootstrap.min.js
/bootstrap.min.css
/popper.min.js
/jquery-3.3.1.slim.min.js
```

The index file references bootstrap css, bootstrap js and its dependencies and shows a Hello world message:

```
<!DOCTYPE html>
<html>

<head>
	<link href="bootstrap.min.css" rel="stylesheet">
	<script src="jquery-3.3.1.slim.min.js"></script>
	<script src="popper.min.js"></script>
	<script src="bootstrap.min.js"></script>
</head>

<body>

	<button type="button" class="btn btn-primary" data-toggle="modal" data-target="#exampleModal">
		Launch Hello World
	</button>

	<div class="modal fade" id="exampleModal" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
		<div class="modal-dialog" role="document">
			<div class="modal-content">
				<div class="modal-header">
					<h5 class="modal-title" id="exampleModalLabel">Modal title</h5>
					<button type="button" class="close" data-dismiss="modal" aria-label="Close">
						<span aria-hidden="true">&times;</span>
					</button>
				</div>
				<div class="modal-body">
					Hello World
				</div>
				<div class="modal-footer">
					<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
					<button type="button" class="btn btn-primary">Save changes</button>
				</div>
			</div>
		</div>
	</div>

</body>

</html>
```

Then in our nginx server configuration, we serve the current location which contains our `index.html`.

```
server {                                                                          
  listen       8080;                                                              
  server_name  localhost;                                                                                  
                                                                                
  location / {                                                                  
      root   /usr/share/nginx/html;                                             
  }                                                                             
}   
```

_If you never seen nginx, you can refer to my previous post where I describe briefly [how to setup nginx on Ubuntu](https://kimsereyblog.blogspot.com/2018/06/asp-net-core-with-nginx.html)._

Once we start nginx, we can navigate to our website and if we look in chrome debugger on the Network tab, we should see the following:

```
Response Headers:

HTTP/1.1 200 OK
Server: nginx/1.15.5
Date: Mon, 15 Oct 2018 08:40:21 GMT
Content-Type: text/css
Content-Length: 140936
Last-Modified: Sun, 14 Oct 2018 18:24:30 GMT
Connection: keep-alive
ETag: "5bc389de-22688"
Accept-Ranges: bytes

Request Headers:

GET /bootstrap.min.css HTTP/1.1
Host: localhost:8080
Connection: keep-alive
Pragma: no-cache
Cache-Control: no-cache
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36
Accept: text/css,*/*;q=0.1
Referer: http://localhost:8080/
Accept-Encoding: gzip, deflate, br
Accept-Language: en-GB,en-US;q=0.9,en;q=0.8
Cookie: jenkins-timestamper-offset=-3600000
```

What we see here is that the request accepts gzip endcoding `Accept-Encoding: gzip` but the response is not gzip'd. We also can see the following size files:

| | | |
|-|-|-|
|localhost|1.4 KB|70 ms|
|bootstrap.min.css|138 KB|56 ms|
|jquery-3.3.1.slim.min.js|68.5 KB|38 ms|
|popper.min.js|20.1 KB|79 ms|
|bootstrap.min.js|50.1 KB|103 ms|
 
## 2. Enable gzip

Gzip module documentation can be found on [nginx documentation](http://nginx.org/en/docs/http/ngx_http_gzip_module.html).
To enable it, we place the following directives under either `http`, `server` or `location`:

```
gzip on;
gzip_types application/javascript image/* text/css;
```

Here we place it under server:

```
server {                                                                          
  listen       8080;                                                              
  server_name  localhost;         
  gzip on;
  gzip_types application/javascript image/* text/css;

  location / {                                                                  
      root   /usr/share/nginx/html;                                             
  }                                                                             
}  
```

By default, the `gzip_types` is only `text/html` therefore here we change it to gzip css, js and images.
Once we restart nginx, we can now observe the following:

```
Response Headers:

HTTP/1.1 200 OK
Server: nginx/1.15.5
Date: Mon, 15 Oct 2018 08:51:15 GMT
Content-Type: text/css
Last-Modified: Sun, 14 Oct 2018 18:24:30 GMT
Transfer-Encoding: chunked
Connection: keep-alive
ETag: W/"5bc389de-22688"
Content-Encoding: gzip
```

The response now contains the encoding `Content-Encoding: gzip`. And the following sizes:

| | | |
|-|-|-|
|localhost|749 B|63 ms|
|bootstrap.min.css|27.8 KB|19 ms|
|jquery-3.3.1.slim.min.js|27.6 KB|37 ms|
|popper.min.js|8.1 KB|77 ms|
|bootstrap.min.js|17.0 KB|82 ms|

As we can observe, the js and css files size are very much reduced. As we can imagine, for SPA like Angular application where we use component libraries, we can get a lot of performance boost out of gzip.

## 3. Extra - test nginx from Windows with Docker container

As an extra, we will see how we can test nginx on Windows by starting it in a Docker container.
We start first by creating a `Dockerfile` which will start from `nginx` and will copy the current directory into `/usr/share/nginx/html` directory.

```
FROM nginx
COPY . /usr/share/nginx/html
```

Then we create a `nginx.conf` file which will replace the default `nginx.conf`.

```
user  nginx;                                                                        
worker_processes  1;                                                                
                                                                                    
error_log  /var/log/nginx/error.log warn;                                           
pid        /var/run/nginx.pid;                                                      
                                                                                    
                                                                                    
events {                                                                            
    worker_connections  1024;                                                       
}                                                                                   
                                                                                    
                                                                                    
http {                                                                              
    include       /etc/nginx/mime.types;                                            
    default_type  application/octet-stream;                                         
                                                                                    
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '       
                      '$status $body_bytes_sent "$http_referer" '                   
                      '"$http_user_agent" "$http_x_forwarded_for"';                 
                                                                                    
    access_log  /var/log/nginx/access.log  main;                                    
                                                                                    
    sendfile        on;                                                             
                                                                                    
    keepalive_timeout  65;                                                          

    server {                                                                          
      listen       80;                                                              
      server_name  localhost;           
      gzip  on;      
      gzip_types application/javascript image/* text/css;                                                                                                           
                                                                                    
      location / {                                                                  
          root   /usr/share/nginx/html;                                             
      }                                                                             
    }                                                
}
```

To get that file, I copied it from the default file present in the image. Then we build the image naming it `nginx-test`:

```
docker build -t nginx-test .
```

Lastly we run the container:

```
docker run --name nginx-test -d -p 8080:80 -v c:/Projects/nginx-test/nginx.conf:/etc/nginx/nginx.conf:ro nginx-test
```

And we should now be able to test that our files are well gzip'd when we navigate to `localhost:8080`!

## Conclusion

Today we saw how to enable gzip on nginx. We started by looking into an example with the default behavior where gzip is disabled. Next we enabled it and look into the performance benefits from it and lastly as extra, we look into how we could test nginx in a Docker container so that we could run test in a sandbox. Hope you liked this post, see you next time!