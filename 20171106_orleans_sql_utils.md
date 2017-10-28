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