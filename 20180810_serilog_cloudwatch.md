# Serilog with AWS Cloudwatch on Ubuntu

Few weeks ago we saw [How to configure Serilog to work with different environment](). At the end of the post, we saw briefly how to get the structured logs synced to Cloudwatch. Today we will explore the configuration in more details.

1. Unified Cloudwatch agent
2. Literate and json logs with Serilog

## 1. Unified Cloudwatch agent

The `Unified Cloudwatch agent` can be installed by following the official documentation [https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/UseCloudWatchUnifiedAgent.html](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/UseCloudWatchUnifiedAgent.html). There is a previous version of the Cloudwatch agent, this new version, introduced in December 2017, unifies the collection of metrics and logs for Cloudwatch under the same configuration.

To install the agent, execute the following commands:

```sh
mkdir ~/tmp
cd tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/AmazonCloudWatchAgent.zip
unzip AmazonCloudWatchAgent.zip
sudo install.sh
```

This will install the agent in the `/opt/aws/amazon-cloudwatch-agent/` folder. Once installed, we can configure the agent by creating a `config.json` file. Here is the official documentation of the configuration file [https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)

We can either use the wizard which is present in the `/opt/aws/amazon-cloudwatch-agent/bin` folder or we can directly create the json file:

```json
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

This is the configuration we had in the previous post which we saved under `/opt/aws/amazon-cloudwatch-agent/etc/config.json`. Now to get the agent to pickup the new configuration, we need to run the following command:

```sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json -s
```

This command can also be used when the agent was stopped and we want to start it again. `-a` is used to specify the action, it can be `start`, `stop`, `status` or `fetch-config`. Here we want to fetch the config as it was changed. `-m` is used to specify the machine which the agent run on, `ec2` or on premise.
This configuration reloading action will have as effect to modify the `amazon-cloudwatch-agent.json` and `amazon-cloudwatch-agent.toml` files which are the files used by the agent.

`-a status` can be used to ensure that the agent is actually running:

```
> sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status

{
  "status": "running",
  "starttime": "2018-06-26T09:27:41+00:00",
  "version": "1.201116.0"
}
```

To stop the agent, we can use `-a stop`, then start it again with `-a start`:

```sh
> sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop
> sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
{
  "status": "stopped",
  "starttime": "",
  "version": "1.201116.0"
}
> sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start
> sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
{
  "status": "running",
  "starttime": "2018-06-26T09:42:45+00:00",
  "version": "1.201116.0"
}
```

## 2.

This is the configuration of our logger in json format which we created in [the last post](). But this outputs the logs in a json format.

![json format logs]()

What we can do to have more readible logs is to create a new log group which will contain plain text logs. We do that by adding a File sink without specifying any formatter. Wd also define our own template as extra.

```
```

`:u` will format the timestamp as UTC. It is needed for Cloudwatch to recognize the date and time. If we dont set the template, it will consider it as UTC time as we set previously UTC in the `config.json`.