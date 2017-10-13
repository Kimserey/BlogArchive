# Create a simple Microsoft Orleans application

Last week I presented [an overview of Microsoft Orleans](https://kimsereyblog.blogspot.sg/2017/10/a-first-look-at-microsoft-orleans.html). Gave an explanation on the concepts and keywords which can be found in the framework.
Today I will explain how we can implement a simple Orleans application with a cluster composed by a localhost Silo and with a client within an ASP Net Core Mvc application.
This post will be composed by 3 parts:

```
1. Implement the grains
2. Create the silo
3. ASP Net Core Mvc client
```

## 1. Implement the grains

The grains are the unit of work in an Orleans application. They contain the business logic and ensure that the state is consistent.
In our example we will be implementing a Bank account grain with a withdraw and deposit functionality. There will be a single business rule being that the balance of any account cannot be lower than 0.

We start first by creating the grain interface in a project where we reference `Orleans.Core`.

```
public interface IBankAccount: IGrainWithStringKey
{
    Task Deposit(double a);
    Task Withdraw(double a);
    Task<double> GetBalance();
}
```

The interface defines the functions exposed by the grain. Notice that we inherit from `IGrainWithStringKey` which notifies Orleans that the grain will be found using a key of type string. This interface comes from `Orleans.Core`.
Another import point is that all interaction in Orleans is asynchronous therefore all functions must return a Task.

Next we can create the grain in another project referencing `Orleans.Core`.

```
public class BankAccount : Grain, IBankAccount
{
    double _balance;

    public Task Deposit(double a)
    {
        _balance += a;
        return Task.CompletedTask;
    }

    public Task Withdraw(double a)
    {
        if (a > _balance)
            throw new ValidationException("Balance cannot be inferior to zero.");

        _balance -= a;
        return Task.CompletedTask;
    }

    public Task<double> GetBalance()
    {
        return Task.FromResult(_balance);
    }
}
```

We deposit and withdraw. We also made the validation check which throws an exception when the withdrawal request is higher than balance. 

__The business logic is contained within the grain.__

We finish the implementation by adding `Orleans.CodeGenerator.Build` in the grain interface project. This step is important, we will see in why later.

Next we can create the silo where the grains will run.

## 2. Create the silo

The grains are C# classes with the business logic in. Orleans runtime is in charge of the lifecycle of the grains. The Orleans runtime runs through the SiloHost.
Grains are instantiated, activated, deactivated and GC'ed in the silo.
We start first by creating a console app project and reference `Orleans.Runtime` and `Orleans.Core`.
Next we reference the grains implementations.

__The Silo does not need to reference the interfaces, it only needs the implementations.__

In order to run, a Silo needs to be configured. This is the simplest configuration, `OrleansConfiguration.xml`, we place this file as copy if newer so that it ends up in the bin folder.

```
<?xml version="1.0" encoding="utf-8"?>
<OrleansConfiguration xmlns="urn:orleans">
  <Globals>
    <SeedNode Address="localhost" Port="30000" />
  </Globals>
  <Defaults>
    <Networking Address="localhost" Port="30000" />
    <ProxyingGateway Address="localhost" Port="40000" />
  </Defaults>
</OrleansConfiguration>
```

Within a cluster, silos communicate witb each other through their internal address. It is configured via the `Network` property.
In contrast, clients communicate with a silo via its gateway, defined via the `ProxyingGateway` property.

The `SeedNode` is a special configuration only used in the context of `MemberShipTableGrain` liveness type. It needs to point to the primary silo which holds the memership table.

The `membership table` is a table contains the state of all the silos within a cluster. 
Periodically all silos read the table to check for new silos which recently joined the clustet and ping other alive silos to verify if they are still alive.

With the configuration in place, we can now initialize and start the silo:

```
public class Program
{
    public static void Main(string[] args)
    {
        var silo = new SiloHost("main");
        silo.InitializeOrleansSilo();
        var success = silo.StartOrleansSilo();

        if (!success)
        {
            throw new Exception("Failed to start silo");
        }

        Console.ReadKey();
    }
}
```

Once started, we should see the configuration of the silo printed at the start of the process.

```
Start time: 2017-10-13 13:14:47.472 GMT
Primary node: 127.0.0.1:30023
Platform version info:
   Orleans version: 1.5.1.0 (Release).
   .NET version: 4.0.30319.42000
   OS version: Microsoft Windows NT 6.2.9200.0
   App config file: C:\Projects\OrleansExample\OrleansExample\bin\Debug\OrleansExample.exe.Config
   GC Type=Client GCLatencyMode=Interactive
Global configuration:
   System Ids:
      ServiceId: 00000000-0000-0000-0000-000000000000
      DeploymentId:
   Subnet:
   Seed nodes: 127.0.0.1:30023
   Messaging:
       Response timeout: 00:30:00
       Maximum resend count: 0
       Resend On Timeout: False
       Maximum Socket Age: 10675199.02:48:05.4775807
       Drop Expired Messages: True
       Silo Sender queues: 8
       Gateway Sender queues: 8
       Client Drop Timeout: 00:01:00
       Buffer Pool Buffer Size: 4096
       Buffer Pool Max Size: 10000
       Buffer Pool Preallocation Size: 250
       Maximum forward count: 2
       Fallback serializer:
   Liveness:
      LivenessEnabled: True
      LivenessType: MembershipTableGrain
      ProbeTimeout: 00:00:10
      TableRefreshTimeout: 00:01:00
      DeathVoteExpirationTimeout: 00:02:00
      NumMissedProbesLimit: 3
      NumProbedSilos: 3
      NumVotesForDeathDeclaration: 2
      UseLivenessGossip: True
      ValidateInitialConnectivity: True
      IAmAliveTablePublishTimeout: 00:05:00
      NumMissedTableIAmAliveLimit: 2
      MaxJoinAttemptTime: 00:05:00
      ExpectedClusterSize: 20
   MultiClusterNetwork: N/A
   SystemStore:
      SystemStore ConnectionString: null
      Reminders ConnectionString: null
   Application:
      Defaults:
         Deactivate if idle for: 02:00:00

   PlacementStrategy:
         Default Placement Strategy: RandomPlacement
         Deployment Load Publisher Refresh Time: 00:00:01
         Activation CountBased Placement Choose Out Of: 2
   Grain directory cache:
      Maximum size: 1000000 grains
      Initial TTL: 00:00:30
      Maximum TTL: 00:04:00
      TTL extension factor: 2.00
      Directory Caching Strategy: Adaptive
   Grain directory:
      Lazy deregistration delay: 00:01:00
      Client registration refresh: 00:05:00
   Reminder Service:
       ReminderServiceType: ReminderTableGrain
   Consistent Ring:
       Use Virtual Buckets Consistent Ring: True
       Num Virtual Buckets Consistent Ring: 30
   Providers:
       No providers configured.
Silo configuration:
   Silo Name: main
   Generation: 245596487
   Host Name or IP Address: localhost
   DNS Host Name: SGLT056
   Port: 30023
   Subnet:
   Preferred Address Family: InterNetwork
   Proxy Gateway: 127.0.0.1:40023
   IsPrimaryNode: True
   Scheduler:
         Max Active Threads: 8
         Processor Count: 8
         Delay Warning Threshold: 00:00:10
         Activation Scheduling Quantum: 00:00:00.1000000
         Turn Warning Length Threshold: 00:00:00.2000000
         Inject More Worker Threads: False
         MinDotNetThreadPoolSize: 200
         .NET thread pool sizes - Min: Worker Threads=8 Completion Port Threads=8
         .NET thread pool sizes - Max: Worker Threads=2047 Completion Port Threads=1000
         .NET ServicePointManager - DefaultConnectionLimit=200 Expect100Continue=False UseNagleAlgorithm=False
   Load Shedding Enabled: False
   Load Shedding Limit: 95
   SiloShutdownEventName:
   Debug:
   Tracing:
     Default Trace Level: Info
     TraceLevelOverrides: None
     Trace to Console: True
     Trace File Name: C:\Projects\OrleansExample\OrleansExample\bin\Debug\main-2017-10-13-13.14.47.200Z.log
     LargeMessageWarningThreshold: 85000
     PropagateActivityId: False
     BulkMessageLimit: 5
   Statistics:
     MetricsTableWriteInterval: 00:00:30
     PerfCounterWriteInterval: 00:00:30
     LogWriteInterval: 00:05:00
     WriteLogStatisticsToTable: True
     StatisticsCollectionLevel: Info
```

All those can be configured either through the xml or through code.
We now have the silo ready. We can move on to create the client.

## 3. ASP Net Core Mvc client

For the client we start by creating the project and reference Orleans.Core.

An Orleans client is create using the `ClientBuilder`.

```
var builder = new ClientBuilder().LoadConfiguration();
var client = builder.Build();
client.Connect().Wait();
```

For ASP Net, we want to be able to inject it in our controller therefore we register it on the service collection in the startup.cs:

```
public void ConfigureServices(IServiceCollection services)
{
    services.AddSingleton<IGrainFactory>(sp =>
    {
        var builder = new ClientBuilder().LoadConfiguration();
        var client = builder.Build();
        client.Connect().Wait();
        return client;
    });
    services.AddMvc();
}
```

The client also requires a configuration `ClientConfiguration.xml` which points to the primary silo gateway in the current settings:

```
<ClientConfiguration xmlns="urn:orleans">
  <Gateway Address="localhost" Port="40000"/>
</ClientConfiguration>
```

An Orleans Client is meant to be instantiated once and shared therefore we created as a singleton.
We initialize the singleton on startup too.

```
public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory)
{
    app.ApplicationServices.GetService<IGrainFactory>();
    app.UseMvcWithDefaultRoute();
}
```

We can then reference the grain interfaces and start using it in our controller:

```
[Route("Bank")]
public class BankAccountController: Controller
{
    private IGrainFactory _factory;

    public BankAccountController(IGrainFactory factory)
    {
        _factory = factory;
    }

    [HttpPost("{accountName}/Deposit")]
    public async Task<IActionResult> Deposit(string accountName, [FromBody]double amount)
    {
        var bank = _factory.GetGrain<IBankAccount>(accountName);
        await bank.Deposit(amount);
        return Ok();
    }
}
```

We will now be able to hit the grain using the client on our ASP Net webapp.

In order to be able to call the grains, `Orleans.CodeGenerator.Build` must be added to the interface project and the code generation happen at build time. It should generate the `*.orleans.g.cs` file in `/obj` folder of the grain interface project. If the file is not generated, trying to access a grain will yield the following error:

```
An unhandled exception occurred while processing the request.

InvalidOperationException: Cannot find generated GrainReference class for interface 'Interfaces.IBankAccount'
```

We now have a Silo running in a process and a client connecting to the Silo from an ASP Net Core Mvc web application. 

[More sample are available on my GitHub.](https://github.com/Kimserey/orleans-cluster-consul)

# Conclusion

Today we saw how we could get started with Microsoft Orleans, how we can create grains and grain interfaces, configure and start a silo and finally we saw how we could create a client which gets injected into an ASP.NET Core Mvc web application. Hope you liked this post, see you next time!