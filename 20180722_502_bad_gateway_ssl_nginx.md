# Nginx 502 bad gateway after SSL setup

When proxying a request to an underlying server, it is necessary to validate its SSL certificate. For example, if we have a process running on `https://localhost:5001`, we can configure Nginx to validate the certificate used by `localhost:5001`. But if we miss one step, we face the common error `502 Bad Gateway` returned by Nginx. Today we will see two scenarios where we can face the error and how to fix them:

1. Setup SSL verification
2. Scenario 1: self-signed certificate
3. Scenario 2: upstream server


## 1. Setup SSL verification

We can tell Nginx to verify the underlying SSL by adding the following directives, either on server or location level:

```txt
server {
  // ... more config
  
  proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
  proxy_ssl_verify on;
  proxy_ssl_session_reuse on;

  location / {
    proxy_pass https://localhost:5001/;
  }
}
```

`proxy_ssl_trusted_certificate` indicates to Nginx the location of the trusted CA certificates.
`proxy_ssl_verify on` specifies that the proxied ssl should be verified.

## 2. Scenario 1: self-signed certificate

If `localhost` certificate is already trusted or signed by a trusted root CA, the proxied request will be successful. But if it isn't, Nginx will return `502 Bad Gateway`.

For example, if we have created a self-signed certificate, we will need to add our certificate to the trusted ones. To do that, we can use the `update-ca-certificates` command. We start first by copying our certificate which we used for `localhost` to ` /usr/local/share/ca-certificates/localhost/localhost.crt` which is the location which will be scanned to add user certificates to the trusted CA certs. 

```sh
sudo cp ~/localhost.crt /usr/local/share/ca-certificates/localhost/
sudo update-ca-certificates
```

Once updated, we should now be able to access tne site.

## 3. Scenario 2: upstream server

Continuing on the self-signed certificate, if we created with a `Subject Alternative Name` of `DNS Name=localhost`, the certificate is viewed as valid by Nginx if we proxy to `localhost`. But if we create an `upstream` server, for example:

```txt
upstream test {
   server localhost:5001;
}

server {
  // ... more config
  
  proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
  proxy_ssl_verify on;
  proxy_ssl_session_reuse on;

  location / {
    proxy_pass https://test/;
  }
}
```

We would face again the same `502 Bad Gateway` issue. If we check the Nginx error log, we will see the following error:

```txt
[error] 504#504: *9 upstream SSL certificate does not match "test" while SSL handshaking to upstream, client: ::1, server: , request: "GET /api/values/ HTTP/1.1", upstream: "https://127.0.0.1:5001/api/values/", host: "localhost"
```

This is due to the fact that the name used to be verified against the SSL certificate name is the `$proxy_host` by default, here `test`. To override it, we can use `proxy_ssl_name`.

```txt
upstream test {
   server localhost:5001;
}

server {
  // ... more config
  
  proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
  proxy_ssl_verify on;
  proxy_ssl_session_reuse on;
  proxy_ssl_name localhost;

  location / {
    proxy_pass https://test/;
  }
}
```

We should now be able to access the site again. We wouldn't have to do this if the upstream name matched the common name used in the SSL certificate.

Hope this was helpful, see you next time!