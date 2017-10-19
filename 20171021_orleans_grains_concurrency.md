# Microsoft Orleans Grains Concurrency Handling (Microsoft Orleans Part 3)

Few weeks ago [I explained the benefits of using Microsoft Orleans](https://kimsereyblog.blogspot.sg/2017/10/a-first-look-at-microsoft-orleans.html). One of them was the implementation of the actor pattern. Today I will dig deeper into it by revisiting a common scenario present in today systems and how it can be solved with Orleans grains.
This post will be composed by 3 parts:

```
1 - Traditional system
2 - The problems
3 - Grain solution
```

## 1. Traditional system

In a traditional system, we can often see a N-tier architecture (usually 3-tier) composed by the following:

```
Front end -> Service tier -> Database
```

The front end being the webserver like ASP NET. The service tier being a set of stateless services containing business logic. They ensure the consistency of the system by extracting the latest state of business object from the database, validate business rules and write back to database ~ the last tier. In this sort of architecture, the database is the source of truth.

This can be illustrated with the following example of a bank account with 4 rules:

```
1. The user can deposit and withdraw from a bank account.
2. Withdrawal is only permitted if the amount is higher or equal to the balance of the account.
3. Deposit is always allowed.
4. Only the owner can withdraw money.
```

```
class BankAccountService
{
    IStorage _storage;

    public BankAccount(IStorage storage)
    {
        _storage = storage;
    }

    public void SetOwner(Guid accountId, string ownerName)
    {
        var owner = _storage.GetOwner(accountId);
        owner.Name = ownerName;
        _storage.SaveOwner(owner);
    }

    public void Deposit(Guid accountId, decimal amount)
    {
        var bankAccount = _storage.GetBankAccount(accountId);
        bankAccount.Balance += amount;
        _storage.SaveBankAccount(bankAccount);
    }    

    public void Withdraw(Guid accountId, string ownerName, decimal amount)
    {
        var bankAccount = _storage.GetBankAccount(accountId);
        var owner = _storage.GetOwner(accountId);

        if (bankAccount.Balance < amount)
            throw new ValidationException("Amount withdrawn must be lower or equal to balance.");

        if (owner.Name != ownerName)
            throw new ValidationException("Only the owner is allowed to withdraw.");

        bankAccount.Balance -= amount;
        _storage.SaveBankAccount(bankAccount);
    }
}
```

Behind `IStorage`, the implementation fetch and write to the database.

The second business rule is ensured by doing the following:
1. The storage hits the db to get the latest status, 
2. then we ensure that there is enough money before we deduct the amount,
3. then save the account back to database

This service, even though stateless, has a major drawback, __it isn't thread safe__. Meaning this service is not guaranteed to yield predictable results if multiple threads call its functions concurrently.

## 2. The problems

Thread safety is one of the main problem modern system face. How can we allow our system to execute multiple concurrent transactions while keeping a consistent output?

One common scenario, starting from a zero balance, could be if a `Deposit` happens slightly before a `Withdrawal`, both running on different threads. There will be 2 possible results:
- Saving deposit amount happens before withdraw validation is done and the withdraw can be executed
- Withdraw validation happens before deposit therefore a validation exception is thrown

__Without thread safety, it is impossible to predicte the result.__

In order to bring back the consistency in the system, a concurrency control must be implemented:

__Optimistic concurrency__ assumes that the changes done on the __same__ resource do not happen frequently therefore instead of locking the resource, it tracks if the resource changed from the time it was read. Depending on the way we handle the result, we can either overwrite the value or just abort the changes.
This works well for most scenarios where updates is not frequent. In the event of having frequent calls, say our  bank account had money withdrawn frequently. We would need to implement another concurrency control.

__Pessimistic concurrency control__ is used when frequent read and write to a resource are required. It is pessimistic in the sense that we assume the worse therefore lock the resource for each transaction. There are two type of locks read and write locks:

- Write lock are needed for read and write on a particular row, write lock means: `I will be changing this row so don't let others read this row until I finish updating it.`
- Read lock are needed to lock the the row for read, read lock means: `I need the data in this row to stay the same during my transaction so don't let anyone change it. But you can let others read if they need.`

In our example, we will need to implement a locking mechanism on all 3 functions, `SetOwner`, `Deposit` and `Withdraw`. In `withdraw` we will acquire a write lock on the bank account and a read lock on the owner. With that, we will ensure that no other thread can access the resource while it is in the current transaction.

The main problem with pessimistic concurrency is that it creates contention as locking is invovled. __The other main problem is that it is the responsability of the developer to create the complex logic around the locking mechanism__.

Therefore three major problems can be seen in a N-tier application:

1. the state of the application is stored in the database involving two round trips are needed, one to fetch the latest state and a second one to write the state after update
2. the database is the source of truth making the system highly reliant on the data saved, the fetch is required to prevent validating business rules on stale data
3. the services contaning the business logic isn't thread safe forcing developers to implement a complex locking mechanism to handle multi threads

__The actor pattern addresses this three problems.__

## 3. Grain solution

In Microsoft Orleans, the implementation of an actor is called a `Grain`. 
Orleans enters into the N-tier by replacing the middle layer and the storage layer by  

```
Front end -> Orleans grains -> Orleans grains storage
```

Instead of having __stateless services__, Orleans comes with __stateful actors__. 

There implementation is very similar to the service we implemented earlier. To implement a bank account grain, we would start first by the interface:

```
interface IBankAccount: IGrainWithGuidKey
{
    Task SetOwner(string ownerName);
    Task Deposit(decimal amount);
    Task Withdraw(string ownerName, decimal amount);
}
```

Then the grain:

```
class BankAccountService: Grain, IBankAccount
{
    string _owner;
    decimal _balance;

    public Task SetOwner(string ownerName)
    {
        _owner = ownerName;
        return Task.CompletedTask;
    }

    public Task Deposit(decimal amount)
    {
        _balance += amount;
        return Task.CompletedTask;
    }    

    public Task Withdraw(string ownerName, decimal amount)
    {
        if (_balance < amount)
            throw new ValidationException("Amount withdrawn must be lower or equal to balance.");

        if (_owner != ownerName)
            throw new ValidationException("Only the owner is allowed to withdraw.");

        _balance -= amount;
        return Task.CompletedTask;
    }
}
```

By moving to Orleans grains, the visible benefit we eliminated the first and second problems:

1. The state is no longer stored in the database, the actor holds the state therefore no trip is needed, the state is always available in memory
2. The database is no longer the source of truth, the truth is the actor itself which makes the code much closer to OOP as an actor can be seen as an object with behaviours

The last benefit is actually not visible as it is handled by the Orleans runtime:

3. Grains are thread safe in themselves

All grains are assured to be thread safe as each functions of the grain is assured to be called in sequential order synchronously. It is ensured by the Orleans runtime which queues calls. _All grains calls are asynchronous and must return a `Task`_.
It means that if one client calls `Deposit` and another client few second after calls `Withdraw`, `Deposit` will be assured to complete first regardless of when `Withdraw` is called.


# Conclusion

Today we saw the benefit of the actor pattern by moving from a N-tier system to a Microsoft Orleans application. 
Thanks to the Orleans grains, we have eliminated the three major problems found in the service tier of a N-tier system. We, developer, do not need to think about concurrency, it is completed abstracted by Orleans runtime. This allows us to focus on business logic and simplify the code in the grain. Hope you liked this post, if you have any question do not hesitate! See you next time!
