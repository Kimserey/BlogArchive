# Gitlab pipeline

Almost a year ago I wrote about [how we could setup CI/CD with gitlab pipeline](https://kimsereyblog.blogspot.com/2018/06/setup-cicd-pipeline-with-gitlab-for.html). I showed a very simple 3 stages pipeline build/test/deploy. Since then Gitlab has improved considerably their CI tool with features simplifying releases management. Today we will revisit pipelines and introduce few concepts which will help in managing releases.

1. Pipeline
2. Releases
3. Artifacts
4. Environments

## 1. Pipeline

Pipeline are defines as jobs. Each job can be part of a stage in the pipeline and multiple jobs can run concurrently if part of the same stage.

The pipeline is define in a .gitlab-ci.yml file placed at the root of the application.

We can setup our own runner or use a shared runner from Gitlab. The shared runner runs on Docker therefore it's possible to build the dotnet image and build our dotnet application.

Here is the pipeline we will be using as example pipeline:

```
image : microsoft/dotnet:latest

stages:
  - build
  - test
  - package
  - deploy

build:
  stage: build
  script:
    - dotnet build MyApp -c Release
  only:
    - master

test:
  stage: test
  script:
    - dotnet test MyApp -c Release
  only:
    - master

package:
  stage: package
  script:
    - dotnet publish MyApp -c Release
  only:
    - master
    
deploy:
  stage: deploy
  script:
    - echo "Deploy to production"
  only:
    - master
```

We can see that we have four stages `build`, `test`, `package` and `deploy`.

In this pipeline, any commit on master triggers a build and flows till deployment which works fine depending on the commit flow and branching mechanism used but if we have a large amount of commit on master, it isn't ideal due to the fact that we would be constantly deploying. Another issue is that we are not considering versioning and we can only trace deployment by hash commit.

If you need more information, I have written deeper explanations on my previous blog posts [1](https://kimsereyblog.blogspot.com/2018/06/setup-cicd-pipeline-with-gitlab-for.html) and [2](https://kimsereyblog.blogspot.com/2018/08/continuously-deploy-infrastructure-with.html).

## 2. Releases

As we saw in 1) the downside of having a simple pipeline releasing at each commit is that we would be constantly be flooding our environment with new releases.

To address that we can set a __manual trigger__.

```
deploy:
  stage: deploy
  script:
    - echo "Deploy to production"
  when: manual
  only:
    - master
```

Now when we deploy, our pipeline will stop and a manual action will be required:

![manual]()

With this step we can manage what is released. The next issue we identified is the version. Understanding releases by looking at the commit hash is hard. Talking to other colleagues about commit hash is even harder. To counter that we use versions.

If you are not familiar with semantic versioning, I have talked extensively about it in [my previous blog post](https://kimsereyblog.blogspot.com/2018/04/sementic-versioning-for-dotnet.html).

The simplest way is to apply the versioning ourselves throught tags. Meaning if we want to release version 
1.0.0 (commit `abc`), we would tag `abc` with 1.0.0. Following semantix versioning, the next version to tag will be 1.0.1 or 1.1.0 or 2.0.0 depending on what we release.

We also want to only trigger packaging and deployment for tagged commits only. We can achieve that by changing `only: - master` to `only: - tags`

```
build:
  stage: build
  script:
    - dotnet build MyApp -c Release

test:
  stage: test
  script:
    - dotnet test MyApp -c Release

package:
  stage: package
  script:
    - dotnet publish MyApp -c Release
  only:
    - tags
    
deploy:
  stage: deploy
  script:
    - echo "Deploy to production"
  only:
    - tags
```

With those changes on the pipeline, normal commits would trigger a pipeline of two stages build/test while tagged commits would trigger pipelines of four stages build/test/package/deploy and of course deployment would require a manual intervention (also called gated stage).

Lastly we can take the tag from the build with the variable `$CI_COMMIT_TAG` and use it when packaging our dotnet application so that our library is built with the version in it. This will be helpful to know in the future which version we are currently using.

```
publish:
  stage: publish
  script:
    - dotnet publish MyApp -c Release /p:Version=$CI_COMMIT_TAG
  only:
    - tags
```

If we looked at the property of the dll generated, we would see the version applied:

![version]()

## 3. Artifacts

Our package stage generates libraries which are deployed to production environment.