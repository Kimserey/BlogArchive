# Versioning for open source library

Few weeks ago I explained how [Gitversion can be used to apply semantic versioning to projects](https://kimsereyblog.blogspot.com/2018/04/sementic-versioning-for-dotnet.html) based on commit and tag history.
Today I will explain a flow which can be followed to version open source project libraries by looking into four important parts in the lifecycle of an open source library.

1. Version with Semantic versioning
2. Branching strategy and Commits
3. Continuous Integration and Releases

## 1. Version with Semantic versioning

[Semantic versioning](https://semver.org/#semantic-versioning-specification-semver) is ideal for versioning libraries. It is formed by three numbers `{major}.{minor}.{patch}`. Each number is used to indicate to the user the level of safety for upgrading the library. 

- Upgrade of the major is risky and has chances to contain breaking changes, therefore looking at release notes or looking for migration would be recommended.
- Upgrade of the minor has lesser risk and can be used to show availability of new features.
- Upgrade of the patch is not risky and is used to push patches.

Following this format allows to have a predictable version number which can be used by applications or libraries to setup upgrade rules and avoiding version lock. 

For example, consider the following:

 - we build a `library A` on version `1.5.0`
 - `library B` references our `library A` on version `1.5.0`
 - `application A` references `library A` on version `1.5.0` and `library B`

We release a new version `1.6.0` with a new feature which `application A` wants to use.
If the versions aren't predictable, both `application A` and `library B` will need to upgrade to `library A` `1.6.0`.
With Semantic version, the version number is predictable and a bump of the `minor` specify no breaking changes. Therefore a compatibility rule on `library A` can be set to support any version of `library B` `1.x.x` as long as it is higher `1.5.0`.

The initial commits before release follow the version `0.x.x`. Before the first `major` bump any releases are to be considered as `alpha`.

## 2. Branching strategy and Commits

For a library, the easiest way is to manage everything around a single `master` branch. And any changes made around `master` is handled as a branch and `pull-request`. 

- When new features need to be added, a branch is made out of `master` and `pull-request`'d back into `master`
- When bug fixes need to be made, a branch is made out of `master` and `pull-request`'d back into `master`
- When an open source contribution on GitHub occurs, the repository is forked and work is done on forked repository `master` and `pull-request`'d back into the main repository `master`

__Every single commit has a version attributed to it.__ This is handle as such:

- For each commit on `master`, the version format is constructed as such `{major}.{minor}.{patch}+{commit}`. For example, for the first commit after release tag `1.2.0`, the version will be `1.2.1+1` while for the fifth commit it will be `1.2.1+5`
- For each commit on a branch, the version format is constructed as such `{major}.{minor}.{patch}-{branch}+{commit}`. For example, `1.2.1-mybranch.1+1`, `1.2.1-mybranch.1+5` or `1.2.1-mybranch.1+3`
- Similarly for pull requests, `1.2.1-PullRequest.1+1`

Once the branches and pull requests are merged, the resulting merge is another commit which then has an attributed version `+{commit}`.

## 3. Continuous Integration and Releases


```
Set the build to the actualy version it is building so that there is no need to navigate back to the commit history to know what it is building.
Once satisfied release by tagging the branch with the number.
```