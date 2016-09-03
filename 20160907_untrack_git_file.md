# Untrack a file previously pushed with Git

Last week I had to untrack a file previously pushed on a git repository and I wasn't sure on how to do it.
So took me a while to wrap my head around the process and today I would like to share that so that it is documented here.

So this post will be very quick, composed by two parts:

 1. Scenario
 2. `git rm --cached`
 3. `git update-index --assume-unchanged`

## 1. Scenario

I have a file `test` already pushed in my repository.

```
> git ls-tree -r master
100644 blob 63123fbe81571b48b7d65602f9828524f9d84b5f	.gitignore
100644 blob a6712f67380bebb75d15c817820e8d2f5c97fb4c	test
```

Now I wanted to untrack the file from the repository.

## 2. `git rm --cached`

Here's the commands I used:

```
> git rm --cached test
> git commit -m "remove test"
> git push
```

So let's see the commands in order.

`rm` is used to remove a file from the index (The index is where the staged changes are held).
It would be the same as manually deleting the file and then staging `git add .` the deletion.

`--cached` is used to specify that __I want to keep my local copy__.

Therefore `rm --cached test` means __"remove test from the index but keep my local copy"__.
And when we execute it, we get the following result:

```
> git status
On branch master
Your branch is up-to-date with 'origin/master'.
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

	deleted:    test

Untracked files:
  (use "git add <file>..." to include in what will be committed)

	test
```

As expected, `test` is deleted and staged - `Changes to be committed: 'deleted: test'` - and it is removed from the index `Untracked files: 'test'`.
I now need to add `test` to `.gitignore` and commit `.gitignore` it will be removed from the untracked files.

Once you push that, __`test` will be removed from the repository but your local copy will still remain and subsequent changes on the file will not be tracked.__

## 3. `git update-index --assume-unchanged`

Now let's say we have another scenario where we actually __do not want to remove the file from the repository__.

To do that you can use the following:

```
> git update-index --assume-unchanged test
```

This will tell git that we won't change the file so no need to track it.
The problem with that is that if we change `test`, our changes won't be tracked and if the file changes on the remote repository, when trying to pull the latest, it will fail.

In that even, we need to undo the `assume-unchanged` then undo our changes to be able to pull again.

```
> git update-index --no-assume-unchanged test
> git checkout test
> git pull
```

__`checkout` revert the changes on the workspace to the index. If you staged the changes, you will need to use `git reset test` before to revert the changes staged on index then you can perform `git checkout test`.__ 

If you need to see what file are `assume-unchanged`, you can run `git ls-files -v`.

```
> git ls-files -v
H .gitignore
h hello
```

The files assume-unchanged are marked with a small `h`.
If you have a lot of files, you can pipe `grep` and specify `start with h` to filter your files.

```
> git ls-files -v|grep '^h'
h hello
```

## Conclusion

Today we saw how we could untrack a file previously pushed on a git repository.
This was useful for me as I previously held a config file in my repository and needed an easy way to untrack it.
Hope you enjoyed reading this post as much as I enjoyed writing it, if you have any comments leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/kimserey_lam).
See you next time!
