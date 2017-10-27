# Understand Silo configuration and Cluster management in Microsoft Orleans (Microsoft Orleans Part 3)

Few weeks ago we saw how to create a Silo and how to implement grains. We also saw how we could create an ASP NET Core web app to talk to the Silo. We discovered the benefits of the single threaded model in grains.
Today we will see one of the other major feature of Orleans, cluster management.

...
1. Build a silo
2. Form a cluster with multiple silo
3. Cluster management with membership
```

## 1. Build a silo

Let's start first by implementing a Silo. We will be using the example we used in the past post.

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

With the following connfiguration:

```
<?xml version="1.0" encoding="utf-8"?>
<OrleansConfiguration xmlns="urn:orleans">
  <Globals>
    <SeedNode Address="localhost" Port="30023" />
  </Globals>
  <Defaults>
    <Networking Address="localhost" Port="30023" />
    <ProxyingGateway Address="localhost" Port="40023" />
  </Defaults>
</OrleansConfiguration>
```

Together with our client configured in `Startup`, we are now able to tall can talk to the grain.

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

With the following configuration:

```
<ClientConfiguration xmlns="urn:orleans">
  <Gateway Address="localhost" Port="40023"/>
</ClientConfiguration>
```

## 2. Form a cluster with multiple silo

We can now modify the Silo to be able to run multiple times on different ports within the same DeploymentId.

```
```

Doing so allows us to boot multiple servers under the same deployment, so called cluster.

We then specify multiple gateways from the client in order for the client to have choices between the gateways available.

When we boot both silo, we can see that the gateways on the client ate both available.

As soon as we shutdown the second silo, the client gets notified.


Once we reboot it, the silo rejoins the cluster succesfully.

## 3. Cluster management with membership

What we have used so far is the MembershipTableGrain.
The membership protocol is the protocol used for the cluster management. Membership refers to a membership list where a list of members are subscribed. The list is the analogy to the table, in MembershipTableGrain, the table of members is stored within the state of a grain within the Primary Silo.

The membership table being stored in the primary silo, if this silo were to go down, the cluster will not be able to survive as all silos will try to request for the latest state table. 
To prevent the entire cluster to go down, Orleans allows us to register a different type of membership storage, for example OrleansSqlUtils.

Two things are needed before being able to start using SqlServer as a membership table:

 1. Change the configuration
 2. Create the Orleans databases

We start first by changing the configuration:

Previous configuration...
New configuration...

We specify that we want to use OrleansSqlUtils and give the connection string linked to our database.

Next we need to create database and table. We start by adding the nuget package.
Inside the package folder we can find a sql script which we will use to create the table. All we need to do is to open it and execute all commands inside it. It will create the membership table and all other necessary tables like reminder table.

```
```

Now that our system is using SqlServer for our membership, our silos will use the membership table in our database to know the latest state of other silos within the cluster.
When we boot our two silos we will notice the following lines written into the table:

```
```

This means that we have 2 silos alive in the system.

Silos periodically read the table to know about new members of the cluster or to know those who recently died.
They will also ping other alive silos and