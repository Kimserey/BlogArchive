# Create alert on disk used with CloudWatch Alarm

Few weeks ago we saw [how to configure CloudWatch to monitor upstream response time from logs](https://kimsereyblog.blogspot.com/2018/11/monitor-upstream-response-time-with.html). We create a CloudWatch configuration which allowed us to create metrics by parsing the logs and create a dashboard out of it. Building up from there, today we will see how we can monitor disk used space and trigger an alarm when the remaining disk space is critical. This post will be composed by three parts:

1. Setup CloudWatch agent to monitor disk space used
2. CloudWatch Metrics
3. CloudWatch Alarm

[AWS Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)

## 1. Setup CloudWatch agent to monitor disk space used

The CloudWatch agent which [we installed previously](https://kimsereyblog.blogspot.com/2018/11/monitor-upstream-response-time-with.html) on our machine to ship logs can be configured to ship default metrics as well. In order to do that all we need to do is to modify the configuration to include the metrics section:

```
{
    "metrics": {
        "metrics_collected": {
            "disk": {
                "measurement": [ "used_percent" ],
                "metrics_collection_interval": 60,
                "resources": [ "/" ]
            }
        }
    },
    "logs": {...}
}
```

We specify that we want to measure `used_percent` at an interval of `60` seconds on the resource `"/"` which is our main volume mountpoint. To figure our volume, we can use `lsblk`: 

```
$ lsblk

NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda    202:0    0   8G  0 disk
└─xvda1 202:1    0   8G  0 part /
```

Once we've done that we can then update our configuration and restart the agent to make sure everything is alright:

```
sudo ./amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:config.json -s
sudo ./amazon-cloudwatch-agent-ctl -a stop
sudo ./amazon-cloudwatch-agent-ctl -a start
```

CloudWatch agent should now be setup to push the disk space metrics to CloudWatch.

## 2. CloudWatch Metrics



```
Metrics > CWAgent > Seach xvda1 disk_used_percent
```

Graphd metrics

Statistic Average
Period 5 minutes

In source:

```
{
    "view": "timeSeries",
    "stacked": false,
    "metrics": [[ "CWAgent", "disk_used_percent", "path", "/", "host", "[ip address]", "device", "xvda1", "fstype", "ext4" ]],
    "region": "ap-southeast-1"
}
```

## 3. CloudWatch Alarm

Create Alarm

Select the metrics

Go to source and paste the source we created earlier or reproduce the same steps to generate the same metrics.

Set a value for the threshold, here we are using disk used in percent therefore we can put `>= 80` for 80%.
And we set the datapoint to `for 3 out of 3 datapoints`.

This means that the check interval is of 15 minutes (3 datapoints of 5 minutes each), and we will trigger an alert if the 3 datapoints are over the threshold.

We also treat the missing data as `missing` which that missing datapoints will just be considered as missing datapoints, not breaching. There are other way of treating missing data, like considering them as `breach` which would be adequate for different alerts. The documentation can be found on the [official AWS documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html).

## Conclusion