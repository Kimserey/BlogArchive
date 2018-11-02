# Monitor Upstream Response Time with Nginx and CloudWatch

Last week we saw how we could [Setup CloudWatch to push logs from our application to CloudWatch](https://kimsereyblog.blogspot.com/2018/11/serilog-with-aws-cloudwatch-on-ubuntu.html). Apart from the application logs, another type of logs that is worth looking into are the access logs from Nginx. Nginx being the entrypoint of the application, every traffic in and out goes through it and today we will see how we can leverage its access logs to monitor the response time of our application from CloudWatch in three parts:

1. Setup Nginx to log upstream response time 
2. Setup logs to be pushed to CloudWatch
3. Setup metrics filter on CloudWatch

## 1. Setup Nginx to log upstream response time

By default Nginx does not log the upstream response time. In order to print it, we can create a new log format which includes it and configure logs to be written into a file using that format. We can add our log configuration in a file called `log_format.conf` which we can place under `/etc/nginx/conf.d/` and nginx will include the configuration under `http` directive by default.

We start first by defining a `log_format` directive:

```
log_format main '[$time_local] '
            '$remote_addr '
            '"$request" '
            '$status '
            '$upstream_response_time '
            'request_length=$request_length '
            'bytes_sent=$bytes_sent '
            'body_bytes_sent=$body_bytes_sent '
            'referer=$http_referer '
            'user_agent="$http_user_agent" '
            'upstream_addr=$upstream_addr '
            'upstream_status=$upstream_status '
            'request_time=$request_time '
            'upstream_response_time=$upstream_response_time ';
```

Then we define where the access log using the format we just defined `main` will be written:

```
access_log /var/log/nginx/myapp.access.log main;
```

Once we are done, we should now have access log printed with the upstream response time.

```
```

## 2. Setup logs to be pushed to CloudWatch

```
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/myapp.*",
                        "log_group_name": "myapp/nginx",
                        "log_stream_name": "access_log",
                        "timezone": "UTC"
                    }
                ]
            }
        },
        "log_stream_name": "default" 
    }
}
```

### 3. Setup metrics filter on CloudWatch

```
[date, client, request="GET /api*", status_code, response_time, data]
```

```
$response_time
```