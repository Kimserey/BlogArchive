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
            '$upstream_response_time';
```

Then we define where the access log using the format we just defined `main` will be written:

```
access_log /var/log/nginx/myapp.access.log main;
```

So here is the full `/etc/nginx/conf.d/log_format.conf` file:

```
log_format main '[$time_local] '
            '$remote_addr '
            '"$request" '
            '$status '
            '$upstream_response_time';

access_log /var/log/nginx/myapp.access.log main;
```

Once we are done, we should now have access log printed with the upstream response time.

```
[02/Nov/2018:17:47:57 +0000] x.x.x.x "GET /myapp HTTP/1.1" 200 0.616
[02/Nov/2018:17:51:23 +0000] x.x.x.x "GET /myapp HTTP/1.1" 200 0.734
[02/Nov/2018:17:54:52 +0000] x.x.x.x "GET /myapp HTTP/1.1" 200 0.634
```

From the access log, we now have valuable information with the upstream response time allowing us to know how long our calls took. 

## 2. Setup logs to be pushed to CloudWatch

If you are not familiar with CloudWatch, refer to my previous blog post where I show how to setup [CloudWatch to push application logs to CloudWatch](https://kimsereyblog.blogspot.com/2018/11/serilog-with-aws-cloudwatch-on-ubuntu.html).

We had the following `config.json`:

```
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/myapp/*.json",
                        "log_group_name": "myapp/json",
                        "log_stream_name": "myapp",
                        "timezone": "UTC",
                        "timestamp_format": "%Y-%m-%dT%H:%M:%S"
                    }
                ]
            }
        },
        "log_stream_name": "default"
    }
}
```

This file was configuring log stream containing the logs from `myapp`. From there, we can add a new source file which will be pushed to a CloudWatch stream called `access_log` under a log group named `myapp/ngin`.

We do that by adding the logs in the `collection_list`:

```
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/myapp/*.json",
                        "log_group_name": "myapp/json",
                        "log_stream_name": "myapp",
                        "timezone": "UTC",
                        "timestamp_format": "%Y-%m-%dT%H:%M:%S"
                    },
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

We make sure that the `file_path` is the path where we saved the access log file.
This will then push our access log to CloudWatch.

We then refrehs the agent:

```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json -s
```

[CloudWatch agent documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)

### 3. Setup metrics filter on CloudWatch

Lastly, because our logs are of a defined format, we can use the metrics filter to create a metrics which will get all `response_time` for the `GET /myapp`
We go to CloudWatch, in the logs, select a log group then click on `Create metric filter`. In the file pattern, we use the Space-Delimited Log Events notation to match a text format:

```
[date, client, request="GET /myapp*", status_code, response_time]
```

This will filter all `Get /myapp` requests as we can see in the example:

![img](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20181228_cw_metrics/metrics.PNG)

We then go next and set the metrics details by naming the metrics and selecting the value as `$response_time`.

![image](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20181228_cw_metrics/name_mnetrics.PNG)

Once created, we can now go to the metrics view and select it to explore the value that we receive.