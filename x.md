# Manage mutable state using actors with a F# Mailbox processor

Today I would like to share a technique that I use to maintain mutable shared state in my F# applications.
This technique uses the `MailboxProcesser`, a simplified implementation of the [actor model](https://www.youtube.com/watch?v=7erJ1DV_Tlo) built into F#.

Here's the issue:

I have a dataframe shared accross my whole application.
The dataframe was constructed at bootup of the server.
It was not scalable as to reconstruct the dataframe, a reboot was needed.
The solution would be to provide a way to mutate the dataframe any time I needed to.
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

This is how the overall structure of the mailbox processor look like:

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

The actor returned exposes method to post messages to the `mailbox`, `Post`, `PostAndReply` and there async equivalend.
The difference is that `Post` returns unit whereas `PostAndReply` gives a return channel that you can pass with the message itself to give the ability to the recepient to respond to the message.

Notice that the whole queuing process is completely abstracted from us. By using `MailboxProcessor`, __we get thread safety on a function execution very easily__.

## 2. Usage in my scenario

```
type ExpenseMessage =
    | Get of replyChannel: AsyncReplyChannel<ExpenseDataFrame>
    | Refresh of dataDirectory: string option 

type ExpenseAgent = {
    Get: unit -> ExpenseDataFrame
    Refresh: string option -> unit
}

type State = {
    DataDirectory: string
    DataFrameState: DataFrameState
} with
    static member Default =
        { DataDirectory = ""
            DataFrameState = NotReady }

    static member SetDir dir x =
        { x with DataDirectory = dir }

    static member BecomeReady frame x =
        { x with DataFrameState = Ready frame }

and DataFrameState =
    | Ready of ExpenseDataFrame
    | NotReady

let build dataDirectory =
    Directory.GetFiles(dataDirectory,"*.csv")
    |> ExpenseDataFrame.FromFile "debug"

let agent =
    let mailbox =
        MailboxProcessor.Start(fun inbox ->
            let rec loop state =
                async {
                    let! msg = inbox.Receive()

                    match msg with
                    | Get replyChannel ->

                        match state.DataFrameState with
                        | Ready expenses  ->
                            // The frame is ready, returns it and wait for next message
                            replyChannel.Reply expenses
                            return! loop state

                        | NotReady ->
                            // The frame is not ready, builds the frame and returns the result and wait for next message
                            let expenses = build state.DataDirectory
                            replyChannel.Reply expenses
                            return! state 
                                    |> State.BecomeReady expenses
                                    |> loop

                    | Refresh (Some newDir) ->
                        // Refresh the frame using the directory provided and wait for the next message
                        let expenses = build newDir
                        return! state     
                                |> State.SetDir newDir 
                                |> State.BecomeReady expenses
                                |> loop

                    | Refresh None ->
                        // Refresh the frame using the current directory set and wait for the next message
                        let expenses = build state.DataDirectory
                        return! state 
                                |> State.BecomeReady expenses
                                |> loop
                }
            loop State.Default)

    { Get = fun () -> mailbox.PostAndReply Get
      Refresh = fun dataDirectory -> mailbox.Post (Refresh dataDirectory) }
```

## Conclusion

