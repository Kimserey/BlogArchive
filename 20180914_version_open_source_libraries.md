# Versioning for open source library

Few weeks ago I explained how [Gitversion can be used to apply semantic versioning to projects](https://kimsereyblog.blogspot.com/2018/04/sementic-versioning-for-dotnet.html) based on commit and tag history.
Today I will dive deeper in the purpose of versioning and introduce a flow which can be followed to version open source project libraries by looking into four important parts in the lifecycle of an open source library.

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

For a library, the easiest way is to manage everything around a single `master` branch and make any changes in a branch (or fork in Github) which will be merged via `pull-request`. 

- When new features need to be added, a branch is made out of `master` and `pull-request`'d back into `master`
- When bug fixes need to be made, a branch is made out of `master` and `pull-request`'d back into `master`
- When an open source contribution on GitHub occurs, the repository is forked and work is done on forked repository `master` and `pull-request`'d back into the main repository `master`

__Every single commit has a version attributed to it.__ This is handle as such:

- For each commit on `master`, the version format is constructed as such `{major}.{minor}.{patch}+{commit}`. For example, for the first commit after release tag `1.2.0`, the version will be `1.2.1+1` while for the fifth commit it will be `1.2.1+5`
- For each commit on a branch, the version format is constructed as such `{major}.{minor}.{patch}-{branch}+{commit}`. For example, `1.2.1-mybranch.1+1`, `1.2.1-mybranch.1+5` or `1.2.1-mybranch.1+3`
- Similarly for pull requests, `1.2.1-PullRequest.1+1`

Once the branches and pull requests are merged, the resulting merge is another commit which then has an attributed version `+{commit}`.

Having a version for each commit becomes very handy when working in a continuously integrated pipeline which we will see next.

## 3. Continuous Integration and Releases

Continuous Integration is a must for open source projects. We must be able to know that `master` branch is always in a workable state. We also must ensure that all pull-requests are valid and do present a danger tobreak `master`. And lastly, we must ensure that other branches created to develop new features are also valid. To do that we would setup a CI server or use a service like [Appveyor](https://www.appveyor.com/).

This is where a unique version for each commit is handy as on each commit pushed to the repository, a build will be triggered where the name of the build will be set to the version of the commit. This allows us to easily identify how the build relates to the repository as we will be able to know for which branch, for which version and which commit from the last release is the build trigger for.

The last important point is to handle releases. Since the library code changes all occur on `master` branch, we do not want to operate in a continuous delivery approach were every change on `master` would yield a release. Instead we can use `tag` to trigger a release which for a .NET library will produce a NuGet package `.nupkg` and generate a release on GitHub with the package attached to the release. Whenever we want to release, we tag the `master` branch with the exact release number.

## Conclusion

Today we saw the different aspects of versioning for an open source library. We started by looking at semantic versioning and the reason why we would follow it. Then we moved to look into branching and how commits are versioned. Lastly we talked about continuous integration and releases. Hope you liked this post, in the next post, I will show how we can achieve the points we discussed today for a .NET library, see you next time!
