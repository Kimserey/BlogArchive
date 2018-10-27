# How to keep fork repository up-to-date

When working on a project where we aren't the owner, it is common behavior to fork the repository. The fork repository is a replicat of the main repository with the only difference being that it is under our own ownership. That allows us to make changes to the project without impacting the main repository. This scenario is very common for contribution, we make commits on our fork repository which will then be merged on the main repository via a pullrequest.
Today we will see how we can setup a fork repository to get latest commit post fork with three steps:

1. Setup an upstream remote
2. Prevent write to upstream
3. Update fork repository master branch

## 1. Setup an upstream remote

Once we fork the repository, our remote origin will now be the fork repository. Therefore any default fetch and pull will be on that repository. To be able to fetch the main repository, we can setup an upstream remote.

```
git remote add upstream [main repository git]
```

For example here I have forked `primeng` repository:

```
$ git remote -v
origin  https://github.com/Kimserey/primeng.git (fetch)
origin  https://github.com/Kimserey/primeng.git (push)
```

After adding the remote `upstream`.

```
$ git remote add upstream https://github.com/primefaces/primeng.git
```

We can now see it on the remote list:

```
$ git remote -v
origin  https://github.com/Kimserey/primeng.git (fetch)
origin  https://github.com/Kimserey/primeng.git (push)
upstream        https://github.com/primefaces/primeng.git (fetch)
upstream        https://github.com/primefaces/primeng.git (push)
```

Now we will be able to fetch the upstream remote which is the main repository.

## 2. Prevent write to upstream

In order to prevent mistakes by write directly into the upstream, we can remove the `push` url. This will then make any write fail and prevent any mistakes.

```
git remote set-url --push upstream disabled
```

This command will replace the git url for push by `disabled`.

```
$ git remote -v
origin  https://github.com/Kimserey/primeng.git (fetch)
origin  https://github.com/Kimserey/primeng.git (push)
upstream        https://github.com/primefaces/primeng.git (fetch)
upstream        disabled (push)
```

## 3. Update fork repository master branch

Now that we have the upstream remote, we can update our master branch by merging the upstream branch in our master branch.
If we haven't changed anything and we just want to update the fork repository to the same state as the main repository, we can reset on the upstream branch.

## Conclusion

Today we saw how to keep a fork repository up-to-date by looking first at how to setup an upstream remote, then making sure that we prevent writes to the main repository and finally looking at options to update our fork repository. Hope you liked this post, see you on the next one!
