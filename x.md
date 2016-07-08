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

This is how the overall structure of the mailbox processor look like.

```
MailboxProcessor.Start(fun inbox ->
    let rec loop state =
        async {
            let! msg = inbox.Receive()
            let newState = ``do something based on message`` msg
            return! loop newState
        }
loop initialState)
```

The four important components are:
 - the `inbox`
 - the `recursive loop`
 - the `message` 
 - the `state` 

## 2. Usage in my scenario

## Conclusion

