# Understand Microsoft Orleans warnings and errors

Microsoft Orleans is a framework which helps building distributed system by implementing the actor model together with the concept of virtual actors, taking care of availability and concurrency. If you are unfamiliar with Microsoft Orleans, you can look at my previous blog post explaining [the benefits of Microsoft Orleans](https://kimsereyblog.blogspot.sg/2017/10/a-first-look-at-microsoft-orleans.html). Even though Orleans promises to abstract the distributed system problems, there are instances where errors arise without us being able to understand what is going on. Lucky us, the logs are well documented... but only for those who can decrypt them.
Today I will go through some of the errors and warnings which can be seen from silo and client so that you too can undestand what is going on. Enjoy!

The code used to produce those errors can be found on my GitHub [https://github.com/Kimserey/orleans-cluster-consul](https://github.com/Kimserey/orleans-cluster-consul). 

## 1. Client logs

Logs on client appears with address `{ip}:0`.

### 1.1. Can't find implementation of interface

```
An unhandled exception occurred while processing the request.

OrleansException: Cannot find an invoker for interface GrainInterfaces.IGrainTwo (ID=610902580,0x2469A234).
```

This first error occurs when the client can't find an implementation for the interface which it tries to get from the grain factory.
This is possible if the code generation hasn't kick off. To fix it, make sure you add the `MS.Orleans.CodeGenerator.Build` in the grain project and in the interface project and when built, make sure the generation kick off. To check if the generation has kick off, a `orleans.g.cs` file should be generated and placed into `/obj` folder in your grain interface project. This is the file containing the implementations.

### 1.2. Target silo became unavailable

```
An unhandled exception occurred while processing the request.

SiloUnavailableException: The target silo became unavailable for message: Request *cli/71849695@18418ea8->S127.0.0.1:40222:244531487TypeManagerId@S00000011 #10: global::Orleans.Runtime.IClusterTypeManager:GetClusterTypeCodeMap(). Target History is: <S127.0.0.1:40222:244531487:TypeManagerId:@S00000011>. See https://aka.ms/orleans-troubleshooting for troubleshooting help.
```

This error can be seen when a grain resides in silo, here `40222`, not stated as dead in the membership table but is dead in reality. The client see it as alive and tries to communicate but fails and show this error. 
With a cluster of two silos, the second silo will mark the first one as dead which will make the client aware of the changes and therefore the client will update its own list of alive gateway and request the grain to be spawn in another alive silo

### 1.3. No gateway

```
An unhandled exception occurred while processing the request.

OrleansException: Could not find any gateway in Orleans.Runtime.Host.ConsulBasedMembershipTable. Orleans client cannot initialize.
```

This error happens when there is no silo alive in the cluster, therefore the client cannot find any gateway to communicate with.
If there are silos available, it should appear in the list of live gateway list. The list contains all proxy gateway addresses to access the silos:

```
[2017-10-01 05:48:03.845 GMT     7      INFO    101309  Messaging.GatewayManager        10.0.75.1:0]    Refreshed the live Gateway list. Found 2 gateways from Gateway listProvider: [gwy.tcp://127.0.0.1:40012/244532758, gwy.tcp://127.0.0.1:40063/244530432]. Picked only known live out of them. Now has 2 live Gateways: [gwy.tcp://127.0.0.1:40012/244532758, gwy.tcp://127.0.0.1:40063/244530432]. Previous refresh time was = 1/10/2017 5:47:03 AM
[2017-10-01 05:49:03.887 GMT     7      INFO    101309  Messaging.GatewayManager        10.0.75.1:0]    Refreshed the live Gateway list. Found 2 gateways from Gateway listProvider: [gwy.tcp://127.0.0.1:40012/244532758, gwy.tcp://127.0.0.1:40063/244530432]. Picked only known live out of them. Now has 2 live Gateways: [gwy.tcp://127.0.0.1:40012/244532758, gwy.tcp://127.0.0.1:40063/244530432]. Previous refresh time was = 1/10/2017 5:48:03 AM
[2017-10-01 05:50:03.929 GMT     7      INFO    101309  Messaging.GatewayManager        10.0.75.1:0]    Refreshed the live Gateway list. Found 2 gateways from Gateway listProvider: [gwy.tcp://127.0.0.1:40012/244532758, gwy.tcp://127.0.0.1:40063/244530432]. Picked only known live out of them. Now has 2 live Gateways: [gwy.tcp://127.0.0.1:40012/244532758, gwy.tcp://127.0.0.1:40063/244530432]. Previous refresh time was = 1/10/2017 5:49:03 AM
```

## 2. Silo Logs

Logs on silo appears with `{ip}:{port}`

### 2.1 Silo restart on same address

```
[2017-10-01 05:24:53.407 GMT    16      WARNING 100619  MembershipOracle        127.0.0.1:30222]    Detected older version of myself - Marking other older clone as Dead -- Current Me=S127.0.0.1:30222:244531487 Older Me=S127.0.0.1:30222:244530878, Old entry= SiloAddress=S127.0.0.1:30222:244530878 SiloName=SGLT056-30222 Status=Active
```

The silo detects that it has restarted and deprecate its old address by adding itself in the suspect silo list on theold address.

### 2.2 Silo joining cluster

```
[2017-10-01 09:52:47.631 GMT    18      INFO    100612  MembershipOracle        127.0.0.1:30017]        Will watch (actively ping) 1 silos: [S127.0.0.1:30007:244547490]
[2017-10-01 09:52:47.633 GMT    18      INFO    100645  MembershipOracle        127.0.0.1:30017]        -ReadAll (called from BecomeActive, after local view changed, with removed duplicate deads) Membership table: 2 silos, 2 are Active, 0 are Dead, Version=<0, 0>. All silos: [SiloAddress=S127.0.0.1:30007:244547490 SiloName=SGLT056-30007 Status=Active, SiloAddress=S127.0.0.1:30017:244547560 SiloName=AFTSGLT056-30017 Status=Active]
```

### 2.3 Silo going down

When there are two silos within the same cluster, they can look for each other and detect each other failures. Let's say we have two silos, one on `30007` and the other on port `30017`, when `30007`

```
Could not connect to 127.0.0.1:30007: ConnectionRefused
Exception = Orleans.Runtime.OrleansException: Could not connect to 127.0.0.1:30007: ConnectionRefused
   at Orleans.Runtime.SocketManager.Connect(Socket s, IPEndPoint endPoint, TimeSpan connectionTimeout)
   at Orleans.Runtime.SocketManager.SendingSocketCreator(IPEndPoint target)
   at Orleans.Runtime.LRU`2.Get(TKey key)
   at Orleans.Runtime.Messaging.SiloMessageSender.GetSendingSocket(Message msg, Socket& socket, SiloAddress& targetSilo, String& error)

[2017-10-01 09:58:15.695 GMT    22      WARNING 101021  Runtime.Messaging.SiloMessageSender/PingSender  127.0.0.1:30017]        Exception getting a sending socket to endpoint S127.0.0.1:30007:244547490

Exc level 0: Orleans.Runtime.OrleansException: Could not connect to 127.0.0.1:30007: ConnectionRefused
   at Orleans.Runtime.SocketManager.Connect(Socket s, IPEndPoint endPoint, TimeSpan connectionTimeout)
   at Orleans.Runtime.SocketManager.SendingSocketCreator(IPEndPoint target)
   at Orleans.Runtime.LRU`2.Get(TKey key)
   at Orleans.Runtime.Messaging.SiloMessageSender.GetSendingSocket(Message msg, Socket& socket, SiloAddress& targetSilo, String& error)
[2017-10-01 09:58:15.736 GMT    20      WARNING 100613  MembershipOracle        127.0.0.1:30017]        -Did not get ping response for ping #33 from S127.0.0.1:30007:244547490. Reason = Original Exc Type: Orleans.Runtime.OrleansMessageRejectionException Message:Silo S127.0.0.1:30017:244547560 is rejecting message: Request S127.0.0.1:30017:244547560MembershipOracle@S0000000f->S127.0.0.1:30007:244547490MembershipOracle@S0000000f #677: global::Orleans.Runtime.IMembershipService:Ping(). Reason = Exception getting a sending socket to endpoint S127.0.0.1:30007:244547490
```

At the same time on the client, we can see the following warning when silo goes down:

```
[2017-10-01 06:04:43.697 GMT    28      WARNING 100912  Messaging.GatewayConnection/GatewayClientSender_gwy.tcp://127.0.0.1:40063/244530432     10.0.75.1:0]    Marking gateway at address gwy.tcp://127.0.0.1:40063/244530432 as Dead in my client local gateway list.
```

# Conclusion

Today we saw some common logs which can be found on silos and clients. Understanding the logs of Orleans allowed me to understand how the flow works which I believe is always beneficial rather than simply using the framework and expecting it to always work. As usual, if you have any question leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam)! See you next time!