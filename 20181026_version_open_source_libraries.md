# Versioning for open source library

Few weeks ago I explained how [Gitversion can be used to apply semantic versioning to projects](https://kimsereyblog.blogspot.com/2018/04/sementic-versioning-for-dotnet.html) based on commit and tag history.
Today I will explain a flow which can be followed to version open source project libraries by looking into four important parts in the lifecycle of an open source library.

1. Version with Semantic versioning
2. Branching strategy
3. Continuous integration
4. Releases

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

## 2. Branching strategy

For a library, the easiest way is to 



Version each commit
1.2.1+1
1.2.1+2
1.2.1+3

Version branches
1.2.1-mybranch+1
1.2.1-mybranch+2
1.2.1-mybranch+3

Version pull requests
1.2.1

Set the build to the actualy version it is building so that there is no need to navigate back to the commit history to know what it is building.

Once satisfied release by tagging the branch with the number.


We operate on a single branch master.

At each commit a build is triggered. This is used to know that the master

Each commit have a unique predictable version