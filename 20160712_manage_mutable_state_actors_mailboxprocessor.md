# Manage mutable state using actors with a F# Mailbox processor

Today I would like to share a technique that I use to maintain mutable shared state in my F# applications.
This technique uses the `MailboxProcesser`, a simplified implementation of the [actor model](https://www.youtube.com/watch?v=7erJ1DV_Tlo) built into F#.

Here's the issue:

I have a dataframe shared accross my whole application.
The dataframe is constructed at bootup of the server which makes the application not scalable as to reconstruct the dataframe, a reboot is needed.
The solution would be to provide a way to mutate the dataframe any time I need to.
But mutable state involves concurrency issues and that's where the `MailboxProcesser` comes to the rescue.

__This is what the `MailboxProcesser` gives a thread safe way to perform operations on a shared object.__

This post is composed by two parts:
 1. Introduction of the `MailboxProcessor`
 2. Usage in my scenario

## 1. Introduction of the `MailboxProcessor`

`MailboxProcessor` can be seen a `mailbox`.
It contains an `inbox` available to the recipient.
We post letters (I call those `messages`) to the `mailbox` and the recipient receives it via her `inbox`.
__Each messages are placed in a queue and dequeued at the rhythm of the recepient.__
Therefore the whole interactions with the recepient is __completely concurrent safe as each message is guaranteed to be delivered one by one in the order by which they were received.__

_Althought the mailboxprocessor is a simplified version as it does not cross applications boundaries and does not survives reboot._

This is how the overall structure of the mailbox processor looks like:

```
let actor =
    MailboxProcessor.Start(fun inbox ->
        let rec processMessage state =
            async {
                let! msg = inbox.Receive()
                let newState = ``do something based on message`` msg
                return! processMessage newState
            }
    loop initialState)

... somewhere else ...

actor.Post MessageA
actor.PostAndReply MessageB
```

The four important components are:
 - the `inbox`
 - the `processMessage` function
 - the `do something based on message` function
 - the `state` 

As we described earlier, we can see the `MailboxProcessor` as a mailbox via which can post `messages` to.
F# makes it very easy as a `message` can be represented as a discriminated union - we will see more later.
The `Start` function of the `MailboxProcessor` takes a function as argument which represents the recipient execution:
 
  - receive a message - done using the `inbox` with the `Receive` function
  - do something with that message and `become` new state - done inside the function which handle the message and alter the state of the actor
  - ready to receive new message using new state - done by recursively looping back on `processMessage` with the new state

The actor returned exposes method to post messages to the `mailbox`, `Post`, `PostAndReply` and their async equivalent.
The difference is that `Post` returns unit whereas `PostAndReply` gives a return channel that you can pass with the message itself to give the ability to the recepient to respond to the message.

Notice that the whole queuing process is completely abstracted from us. By using `MailboxProcessor`, __we get thread safety on a function execution very easily__.

## 2. Usage in my scenario

I have a dataframe shared accross my whole application.
The dataframe used to be immutable therefore only built one time on server bootup but I now need to update it on the fly.

I defined the actor by stages:
 
 1. the messages
 2. the states
 3. the process
 4. the api

### 2.1 The messages

I need to `Refresh` the dataframe and `Get` it.

```
type ExpenseMessage =
    | Get of replyChannel: AsyncReplyChannel<ExpenseDataFrame>
    | Refresh 
```

`Get` takes a replyChannel argument, this will be provided by the `mailbox processor`.
`Refresh` will be used to instruct the system to rebuild the dataframe.

### 2.2 The states

The benefit of an actor is that it is stateful.
Since concurrency is abstracted away from the main function, it is easy to understand the flow and react properly to messages.

My actor will have two states, `Ready` and `NotReady`.

```
DataFrameState =
  | Ready of ExpenseDataFrame
  | NotReady
```

Depending on which states it is in, it will behave differently when it receives a message.

### 2.3 The process

The process contains three paths:

 - path 1: `Get` is received and the actor state is `Ready`, the expenses are returned through the `replyChannel` and the actor remains `Ready` and wait for the next message
 - path 2: `Get` is received and the actor is `NotReady`, it builds the frame and returns the result through the `replyChannel` and becomes `Ready` and wait for the next message
 - path 3: `Refresh` is received, not matter which state the actor is in, the frame is rebuilt and the actor becomes `Ready` with the new frame and wait for the next message

```
let buildFrame() =
    Directory.GetFiles(dataDirectory,"*.csv")
    |> ExpenseDataFrame.FromFiles

let agent =
    let mailbox =
        MailboxProcessor.Start(fun inbox ->
            let rec loop state =
                async {
                    let! msg = inbox.Receive()

                    match msg with
                    | Get replyChannel ->

                        match msg with
                        | Ready expenses  ->
                            // path 1
                            replyChannel.Reply expenses
                            return! loop state

                        | NotReady ->
                            // path 2
                            let expenses = buildFrame() 
                            replyChannel.Reply expenses
                            return! Ready expenses

                    | Refresh ->
                        // path 3
                        let expenses = buildFrame()
                        return! Ready expenses
                }
            loop State.Default)
```

### 2.4 The api

We could just use directly the `MailboxProcessor` and `Post` messages to it but it is best to not expose our infrastructure - the `MailboxProcessor`.
Someone sending messages doesn't need to know that a `AsyncReplyChannel<_>` is involved in a `Get`.
To cater for that, we construct an `Api` which provides more abstract functions to interact with our agent.

```
type Api = {
    Get:     unit -> ExpenseDataFrame
    Refresh: unit -> unit
}
```

And here would be the instantiation of the Api:

```
let actor =
    let mailbox =
        ... mailbox code ...

    { Get     = fun () -> mailbox.PostAndReply Get
      Refresh = fun () -> mailbox.Post Refresh }
```

And we are done! We provided a completely thread safe solution for our issue.

## Conclusion

`MailboxProcessor` being built into F#, it is one of the best way to handle shared mutable state in an F# application.
Concurrency issues are always tricky so I rather leave it to the system to optimise for it as much as I can.
I hope this tutorial was useful, let me know if you liked it. As always if you have any question leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam).
See you next time!

## Resources
    
 - The code related to this post: [https://github.com/Kimserey/DataExpenses/blob/master/London.Core/ExpenseDataFrame.fs#L361](https://github.com/Kimserey/DataExpenses/blob/master/London.Core/ExpenseDataFrame.fs#L361)
 - Where my scenario come from: [https://kimsereyblog.blogspot.co.uk/2016/04/a-primer-on-manipulating-data-frame.html](https://kimsereyblog.blogspot.co.uk/2016/04/a-primer-on-manipulating-data-frame.html)
 - More on dataframes with Deedle: [https://kimsereyblog.blogspot.co.uk/2016/04/a-primer-on-manipulating-data-frame.html](https://kimsereyblog.blogspot.co.uk/2016/04/a-primer-on-manipulating-data-frame.html)
