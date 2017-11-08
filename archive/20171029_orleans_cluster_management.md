# Understand Silo configuration and Cluster management in Microsoft Orleans (Microsoft Orleans Part 3)

Few weeks ago we saw how to create a Silo and how to implement grains. We also saw how we could create an ASP NET Core web app to talk to the Silo. We discovered the benefits of the single threaded model in grains. Today we will see one of the other major feature of Orleans, cluster management. This post will be composed by 3 parts:

```
1. Build a silo
2. Form a cluster with multiple silos
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

## 2. Form a cluster with multiple silos

We can now modify the Silo to be able to run multiple times on different ports within the same DeploymentId.

```
public class Program
{
    public static void Main(string[] args)
    {
        var primaryEndpoint = new IPEndPoint(IPAddress.Loopback, Int32.Parse(args[2]));
        var siloEndpoint = new IPEndPoint(IPAddress.Loopback, Int32.Parse(args[0]));
        var gatewayEntpoint = new IPEndPoint(IPAddress.Loopback, Int32.Parse(args[1]));

        var silo = new SiloHost(Dns.GetHostName() + "@" + args[0]);
        silo.LoadOrleansConfig();
        silo.Config.Globals.DeploymentId = "main";
        silo.SetProxyEndpoint(gatewayEntpoint);
        silo.SetSiloEndpoint(siloEndpoint, 0);
        silo.SetPrimaryNodeEndpoint(primaryEndpoint);
        silo.SetSeedNodeEndpoint(primaryEndpoint);
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

Here we allow taking the endpoints as arguments so that we can bootup multiple silos under the same "main" cluster.
The first port being the silo port, next the silo gateway port and the last one being the primary node (also being the seed node). We can then open two command prompt and run the two following commands to start a cluster with a primary node on port 30001:

```
.\OrleansExample.exe 30001 40001 30001
.\OrleansExample.exe 30020 40020 30001
```

Doing so allows us to boot multiple servers under the same deployment, so called cluster.
Next we change the client configuration in order for the client to have choices between the two gateways available.

```
<ClientConfiguration xmlns="urn:orleans">
  <Gateway Address="localhost" Port="40001"/>
  <Gateway Address="localhost" Port="40020"/>
</ClientConfiguration>
```

We now endup with 2 silos forming a cluster and a client having access to that cluster. With this setup, we can now scale by adding booting more silos and grains will be spread among those silos by the Orleans runtime.
The management of the silos is left to the runtime which uses a membership table.

## 3. Cluster management with membership

The cluster management in Orleans works via a membership table. Its main purpose is to answer the following questions: 
- How can a silo join the cluster? 
- How do other silos get notified that another silo went down?
- How do clients know which gateway is available?

__Joining a cluster__

When using a `MembershipTableGrain`, the primary node is the one holding the membership. __The primary node must be the one that start first.__
Then when a silo tries to join the cluster, it looks for the primary node and ping the nodes stated as alive to join the cluster. It can be seen in the logs of the silo trying to join the cluster:

```
[2017-10-28 00:45:06.530 GMT    12	INFO   	100614	MembershipOracle	127.0.0.1:30030]	About to send pings to 2 nodes in order to validate communication in the Joining state. Pinged nodes = [
    [SiloAddress=S127.0.0.1:30001:246847086 SiloName=SGLT056-30001 Status=Active HostName=SGLT056 ProxyPort=40001 RoleName=OrleansExample UpdateZone=0 FaultZone=0 StartTime = 2017-10-28 00:38:08.406 GMT IAmAliveTime = 2017-10-28 00:43:10.682 GMT Suspecters = [] SuspectTimes = []], 
    [SiloAddress=S127.0.0.1:30020:246847347 SiloName=SGLT056-30020 Status=Active HostName=SGLT056 ProxyPort=40020 RoleName=OrleansExample UpdateZone=0 FaultZone=0 StartTime = 2017-10-28 00:42:29.147 GMT IAmAliveTime = 2017-10-28 00:42:33.866 GMT Suspecters = [] SuspectTimes = []]
]	
```

Once the communication is established, the silo marks itself in the membership table as alive and read the alive nodes in the cluster. For example let's assume we have been running multiple silos and some went down already and we are booting a silo on 30020:

```
[2017-10-28 00:45:06.557 GMT    14	INFO   	100634	MembershipOracle	127.0.0.1:30030]	-ReadAll (called from BecomeActive) Membership table 4 silos, 3 are Active, 1 are Dead, Version=<9, 23>. All silos: [SiloAddress=S127.0.0.1:30001:246847086 SiloName=SGLT056-30001 Status=Active, SiloAddress=S127.0.0.1:30020:246847347 SiloName=SGLT056-30020 Status=Active, SiloAddress=S127.0.0.1:30030:246847496 SiloName=SGLT056-30030 Status=Active, SiloAddress=S127.0.0.1:30020:246847106 SiloName=SGLT056-30020 Status=Dead]	
```

_The number postfixed with the silo address is a timestamp which avoid silos to be written in the table with the same key._  
There are `3` `Active` silos, where one of them being us 30030, the other active silos being `30001` and `30030`.
After this point, the silo will start to monitor its connection with the alive silos by actively pinging them. The log specifying this behavior can be seen on the silo logs:

```
[2017-10-28 00:45:06.614 GMT    14	INFO   	100612	MembershipOracle	127.0.0.1:30030]	Will watch (actively ping) 2 silos: [S127.0.0.1:30001:246847086, S127.0.0.1:30020:246847347]	
```

Lastly some cleaned up are performed and the table is read for a last time:

```
[2017-10-28 00:45:06.619 GMT    14	INFO   	100645	MembershipOracle	127.0.0.1:30030]	-ReadAll (called from BecomeActive, after local view changed, with removed duplicate deads) Membership table: 4 silos, 3 are Active, 1 are Dead, Version=<9, 23>. All silos: [SiloAddress=S127.0.0.1:30001:246847086 SiloName=SGLT056-30001 Status=Active, SiloAddress=S127.0.0.1:30020:246847347 SiloName=SGLT056-30020 Status=Active, SiloAddress=S127.0.0.1:30030:246847496 SiloName=SGLT056-30030 Status=Active, SiloAddress=S127.0.0.1:30020:246847106 SiloName=SGLT056-30020 Status=Dead]	
```

Which then conclude the process of the silo joining the cluster. This process is known as the `activation` of a silo. It is contained within the following logs:

```
-BecomeActive	
...
-Finished BecomeActive.	
```

__Exiting a cluster__

All silos pings each other actively and therefore will know when other silos are down. When one of the silos goes down, it will eventually be marked as dead the membership table. This can be seen in the following logs on the silo actively pinging the dead silo:

Let's simulate a silo failure in a cluster composed of 3 silos buy boot 3 silos (`30001`, `30020`,`30030`) and then shutdown `30030`. As we saw earlier, as soon as a silo joins, it starts to actively ping other silos and other silos start to actively ping it.
Therefore a failure will result in ping failures from its siblings silos:

For `30001`:

```
[2017-10-28 01:18:15.089 GMT    13	WARNING	100613	MembershipOracle	127.0.0.1:30001]	-Did not get ping response for ping #7 from S127.0.0.1:30030:246849451. Reason = Original Exc Type: Orleans.Runtime.OrleansMessageRejectionException Message:Silo S127.0.0.1:30001:246849436 is rejecting message: Request S127.0.0.1:30001:246849436MembershipOracle@S0000000f->S127.0.0.1:30030:246849451MembershipOracle@S0000000f #242: global::Orleans.Runtime.IMembershipService:Ping(). Reason = Exception getting a sending socket to endpoint S127.0.0.1:30030:246849451	
```

For `30020`:

```
[2017-10-28 01:18:17.271 GMT    14	WARNING	100613	MembershipOracle	127.0.0.1:30020]	-Did not get ping response for ping #9 from S127.0.0.1:30030:246849451. Reason = Original Exc Type: Orleans.Runtime.OrleansMessageRejectionException Message:Silo S127.0.0.1:30020:246849443 is rejecting message: Request S127.0.0.1:30020:246849443MembershipOracle@S0000000f->S127.0.0.1:30030:246849451MembershipOracle@S0000000f #182: global::Orleans.Runtime.IMembershipService:Ping(). Reason = Exception getting a sending socket to endpoint S127.0.0.1:30030:246849451
```

Which trigger votes to mark it as dead:

`30001` being the first voter, it will put its vote to mark `30030` as dead.

```
[2017-10-28 01:18:15.110 GMT    13	INFO   	100610	MembershipOracle	127.0.0.1:30001]	-Putting my vote to mark silo S127.0.0.1:30030:246849451 as DEAD #2. Previous suspect list is [], trying to update to [<S127.0.0.1:30001:246849436, 2017-10-28 01:18:15.108 GMT>], eTag=14, freshVotes is []	
```

`30020` being the last voter, as `30001` already placed its vote in the `suspect list`, it will go and mark `30030` as dead:

```
[2017-10-28 01:18:17.278 GMT    14	INFO   	100611	MembershipOracle	127.0.0.1:30020]	-Going to mark silo S127.0.0.1:30030:246849451 as DEAD in the table #1. I am the last voter: #freshVotes=1, myVoteIndex = -1, NumVotesForDeathDeclaration=2 , #activeSilos=3, suspect list=[<S127.0.0.1:30001:246849436, 2017-10-28 01:18:15.108 GMT>]	
```

Next after having marked `30030` as dead, `30020` is now the one with latest information about the changes in the table and notifies others to read again the table:

```
[2017-10-28 01:18:17.298 GMT    14	INFO   	100612	MembershipOracle	127.0.0.1:30020]	Will watch (actively ping) 1 silos: [S127.0.0.1:30001:246849436]
```

Which provoke an update in `30001`:

```
[2017-10-28 01:18:17.317 GMT    10	INFO   	100612	MembershipOracle	127.0.0.1:30001]	Will watch (actively ping) 1 silos: [S127.0.0.1:30020:246849443]	
[2017-10-28 01:18:17.319 GMT    10	INFO   	100645	MembershipOracle	127.0.0.1:30001]	-ReadAll (called from gossip, after local view changed, with removed duplicate deads) Membership table: 3 silos, 2 are Active, 1 are Dead, Version=<8, 19>. All silos: [SiloAddress=S127.0.0.1:30001:246849436 SiloName=SGLT056-30001 Status=Active, SiloAddress=S127.0.0.1:30020:246849443 SiloName=SGLT056-30020 Status=Active, SiloAddress=S127.0.0.1:30030:246849451 SiloName=SGLT056-30030 Status=Dead]	
```

Notice the time, as soon as `30020` marks `30030` as dead, it pings `30001` and then `30001` updates its watch and read back the table. This is how the cluster is managed together with the membership, silos are able to know when other silos join the cluster and when other silos exit the cluster.

All the source code can be found on my GitHub. [https://github.com/Kimserey/orleans-sample](https://github.com/Kimserey/orleans-sample)

# Conclusion

Today we dived into how Orleans manage a cluster of multiple silos. How silos join and leave a cluster and how other siblings are notified. The process is handled by the Membership Oracle which has its data in the membership table. We saw what sort of logs can indicate the current status of the system and understand what is currently happening. We also saw the configuration needed to be able to boot multi silos from the same console app. The cluster management is one of the best feature of Orleans as it abstract from us the concepts of distributed system management. The membership table grain is not recommended to be used in a productive environment as if the primary node goes down, the whole system will not be able to survive. Next week we will look into moving the table to a fault tolerant storage like SQLServer. Hope you like this post! If you have any questions, you know what to do. See you next time!