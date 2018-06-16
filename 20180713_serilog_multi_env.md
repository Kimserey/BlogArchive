# Multi environment logging with Serilog for AspNet Core

Few months ago we saw how to get started with Serilog. We discovered what was Serilog and the different concepts of settings, enrichers and sinks. Today we will see how we can take Serilog further and configure a logging mechanism for an application running in multi environment.

1. Setup Serilog
2. Multi environment
3. AWS CloudWatch

## 1. Setup Serilog

If you have never seen Serilog before you can start with my previous post on [How to get started with Serilog]().

In order to configure our first logging mechanism, we start by creating an AspNet Core application and install `Serilog`, `Serilog.AspNetCore` and the sinks we will be using `Serilog.Sinks.Console`, `Serilog.Sinks.File`.

__RollingFile sink also exists but it has been superseded with File sink.__

Next we can configure the logger to write to Console and write to a file:

```c#
```

We have set the minimun level of the logs to Debug and have overwritten Microsoft to only provide Information level.
We have also configure two sinks, the Console sink to write with the format `...` and using the theme `...` and the File sink which we have configured to rotate files on size limit and keep only 3 files.

Once we run the applicatiom, we should now be able to see the logs from the Console and, at the same time, logs should flow into files at the path specified.

## 2. Multi environment

So far we are logging to the Console and in a file with a Debug minimim level. While having a Debug level is great in development, it is best to restrict to Information the log level for our production environment. Similarly for the sinks, it is best to log to Console only for development hence what we need is two configurations:

1. `development`, with Debug log level and Console sink
2. `production`, with Information log level and File sink

AspNet Core already ship with a powerful configuration framework which we can leverage using `Serilog.Settings.Configuration`.

_If you haven't used AspNet Core configuration, you can have a look at my previous post where I [briefly touch on the Configuration framework]()._

We start by installing the package and setup Serilog using configuration:

```c#
...
```

Next we setup the `appsettings.development.json` to include the settings which will be used in development:

```c#
{
  "serilog": {
    "MinimumLevel": {
      "Default": "Debug",
      "Override": {
        "Microsoft": "Information"
      }
    },
    "WriteTo": [
      {
        "Name": "Console",
        "Args": {
          "theme": "Serilog.Sinks.SystemConsole.Themes.AnsiConsoleTheme::Code, Serilog.Sinks.Console",
          "outputTemplate": "[{Timestamp:HH:mm:ss.fff} {Application} {Level:u3}][{RequestId}] {SourceContext}: {Message:lj}{NewLine}{Exception}"
        }
      }
    ]
  }
}
```

And we create a `appsettings.production.json` which will be used for production:

```c#
{
  "serilog": {
    "MinimumLevel": "Information",
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "path": "/var/log/myapp/myapp.log",
          "fileSizeLimitBytes": 10485760,
          "rollOnFileSizeLimit": true,
          "retainedFileCountLimit": 3
        }
      }
    ]
  }
}
```

When we run now it should only write to Console and no longer to the file when `ASPNETCORE_ENVIRONMENT` is set to 1
`development` or it should only write the file and no longer to the Console if the environment is `production`. The behavior should apply too to the log level.

Note that the path given is a linux path for an AspNet Core application hosted on linux.

## 3. AWS CloudWatch with structured logs

Having the logs written into a file is great to be able to debug in a offline manner as we can refer back to the logs.

Before being written to the file, Serilog logs are actually in a object form called a structured log
This native form is very useful as it allows to provide full control to the receiver of the log to decide how they wish to deal with the log. For example, AWS CloudWatch supports reading json logs which we can then be used to inspect logs in a more efficient way then pure text.

We start first by adding a formatter for the file:

```c#
{
  "serilog": {
    "MinimumLevel": "Information",
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "formatter": "Serilog.Formatting.Compact.CompactJsonFormatter, Serilog.Formatting.Compact",
          "path": "/var/log/myapp/myapp.json",
          "fileSizeLimitBytes": 10485760,
          "rollOnFileSizeLimit": true,
          "retainedFileCountLimit": 3
        }
      }
    ]
  }
}
```

We also install `Serilog.Formatting.Compact` which provides `CompactJsonFormatter`, a formatter which reduce the overal log file size allowing us to log more.We also change the file extension to `.json` since it is now a json file.
Once we run the application we can see that the logs are no longer text but json objects on each lines.

__Assuming that we have deployed our application on a ec2 instance__, we can now install the CloudWatch agent on our server and configure it to ship the content of our logs to CloudWatch.

We start first by adding an IAM Role with inline policy then attach policy to ec2