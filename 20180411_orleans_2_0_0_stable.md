# Microsoft Project Orleans ClientBuilder and SiloBuilder

Prior 2.0.0 stable, we used to configure client and silo using `ClientConfiguration` and `ClusterConfiguration`. I was hard to understand how to configure those as many options were available. Moving forward to 2.0.0 stable, __ClientConfiguration and ClusterConfiguration no longer exist!__ It has now been replaced by a `ClientBuilder` and a `SiloBuilder` (notice there is no cluster builder). The shift toward builders makes life easier to us to configure client and silo. Today I want to take the time to explain how the migration between beta 3 and stable can be done in three parts:

1. Configure ClientBuilder
2. Configure SiloBuilder

## 1. Configure the ClientBuilder

A client needs to connect to a cluster. The only configuration needed for the client is therefore:

1. the id of the cluster
2. the id of the service
3. where to find the cluster

During beta this used to be configured in `ClientConfiguration`, it is now done using the `ClientBuilder`:

```c#
IClusterClient client = new ClientBuilder()
  // 1. and 2. the id of the cluster and id of the service
  .Configure<ClusterOptions>(options =>
  {
      options.ClusterId = "cluster";
      options.ServiceId = "service";
  })
   // 3. where to find the cluster
  .UseAzureStorageClustering(options =>
  {
      options.ConnectionString = "storage connection string";
  })
  .ConfigureApplicationParts(x => x.AddApplicationPart(typeof(IAccount).Assembly).WithReferences())
  .ConfigureLogging(logging => logging.AddConsole())
  .Build();
```

Those settings allow the client to know where to find the cluster by pointing to the location membership table.

## 2. Configure the SiloBuilder

A silo needs more configurations. It is the runtime for the grains. If we leverage the grain storage, the streams and the reminders, we would need to configure the following:

1. the id of the cluster and service
2. where to find the cluster to join it
3. the silo internal port (for silo to silo communication, inter cluster)
4. the silo gateway port (for client communiction)
5. the silo hostname
6. the grain storage
7. the stream service
8. the reminder type and storage if needed

During beta this used to be configured in `ClusterConfiguration`, it is now done using the `SiloBuilder`:

```c#
ISiloHost host = new SiloHostBuilder()
    // 1. the id of the cluster and service
    .Configure<ClusterOptions>(options =>
    {
        options.ClusterId = "";
        options.ServiceId = "";
    })
    // 2. where to find the cluster to join it
    .UseAzureStorageClustering(options => options.ConnectionString = "")
    // 3. and 4. and 5. the ports public/private and the hostname of the silo
    .ConfigureEndpoints(
        siloPort: 22000,
        gatewayPort: 32000,
        hostname: IPAddress.Loopback.ToString()
    )
    // 6. the grain storage
    .AddAzureBlobGrainStorage("default", options =>
    {
        options.ConnectionString = "connection";
        options.ContainerName = "grain-container";
    })
    // This store is needed as rendez point for streams for 7.
    .AddAzureBlobGrainStorage("PubSubStore", options =>
    {
        options.ConnectionString = "";
        options.ContainerName = "";
    })
    // 7. the stream service
    .AddSimpleMessageStreamProvider("default", (SimpleMessageStreamProviderOptions options) =>
    {
        options.FireAndForgetDelivery = true;
    })
    // 8. the reminder type and storage if needed
    .UseInMemoryReminderService()
    .ConfigureApplicationParts(x =>
    {
        x.AddApplicationPart(typeof(AccountGrain).Assembly).WithReferences();
    })
    .ConfigureLogging(b => b.AddConsole())
    .Build();
```

This will allow the silo to boot properly, join the cluster it is meant to be in, save grain state, save reminders and utilise the streams configured.

In the example we demonstrated configuration of a cluster on Azure with all storage using AzureBlobStorage and clustering using AzureTable with stream using AzureStorage queues.

__This is also one of the major changes; the libraries have been split into meaningful libraries and meaningful namespaces.__

- The clustering is provided by the library `Microsoft.Orleans.Clustering.xxx`,
- The storage persistence is provided by the library `Microsoft.Orleans.Persistence.xxx`,
- The reminders are provided by the library `Microsoft.Orleans.Reminders.xxx`.

Here we are using Azure so everything was with `.AzureStorage` but if we were to use AWS, we could import `.DynamoDB` and we will have access to the extensions to use DynamoDB as clustering, backing storage for grains and reminders.

## Further readings

If you are looking for a tutorial on how to get started with Orleans, have a look at my previous tutorials.

- [A first look at Microsoft Orleans](https://kimsereyblog.blogspot.sg/2017/10/a-first-look-at-microsoft-orleans.html?m=1)
- [Create a simple Microsoft Orleans application](https://kimsereyblog.blogspot.sg/2017/10/create-simple-microsoft-orleans.html?m=1)
- [Microsoft Orleans Grains Concurrency Handling](https://kimsereyblog.blogspot.sg/2017/10/microsoft-orleans-grains-concurrency.html?m=1)
- [Silo configuration and Cluster management in Microsoft Orleans](https://kimsereyblog.blogspot.sg/2017/10/silo-configuration-and-cluster.html?m=1)
- [Microsoft Orleans logs warnings and errors](https://kimsereyblog.blogspot.sg/2017/12/microsoft-orleans-logs-warnings-and.html?m=1)