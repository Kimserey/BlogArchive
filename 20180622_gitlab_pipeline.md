# Setup a CI/CD pipeline with Gitlab for ASPNET Core on Ubuntu

Few weeks ago I explained how [we could setup a CI/CD pipeline](https://kimsereyblog.blogspot.com/2017/12/how-to-setup-continuous.html?m=1) whereby the runner would be on Windows and the last stage was to package the application.
Today we will see how we can setup a runner on Ubuntu CI server and use it to build and deploy an ASP MET Core application onto a Ubuntu 16.04 server. This post will be composed by three parts:

1. Setup the runner on the CI server
2. Setup the application on the server
3. Setup the job in our project

If you are unfamiliar with Gitlab pipeline and its terminology, you can read [my previous post where I explain the main concepts behind GitLab pipeline with runner, jobs and stages](https://kimsereyblog.blogspot.com/2017/12/how-to-setup-continuous.html?m=1).
If you are unfamiliar with ssh and systemd, you can read [my previous blog post on useful ssh commands](https://kimsereyblog.blogspot.com/2018/05/useful-bash-and-friends-commands.html?m=1) and [my previous blog post on how to manage Kestrel process with systemd](https://kimsereyblog.blogspot.com/2018/05/manage-kestrel-process-with-systemd.html?m=1).

## 1. Setup the runner on the CI server

Setup the runner on your CI server by getting the package with apt-get.

```sh
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner
```

Next register the runner using the token from your project.

While registering the runner, the tags are used for Gitlab to know which runner should get the job hence it is good to set tags tied to the project, the environment, the os, frameworks and even package manager available.

```sh
sudo gitlab-runner register
```

Once the runner is setup we should be able to see it under the runner configuration.

Next we need to install dotnet for the CI server to be able to build the application.

```sh
wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install dotnet-sdk-2.1
```

Lastly install zip as we will be using it to package all files.

```sh
apt-get update
apt-get install zip
```

## 2. Setup the application on the server

Place the application in the right folders on your server: `/usr/share/myapp` for the runnable binaries.

Install nginx to proxy port 80 to the dotnet Kestrel process.

apt-get nginx

... nginx file

Setup systemd unit to boot the dotnet process and manage it as a service.

... unit file

From here we should be able to access our server on internet.

_If you are unfamiliar with nginx, read my previous blog post on [how to setup Kestrel behind nginx]()._
_If you are unfamiliar with systemd, read my previous blog on [how to manage Kestrel procesz with systemd]()._

## 3. Setup the job in our project

We have a runner setup to run jobs and we have our application already running. What we need to do next is to define the jobs to run to update the running application with the latest build once we push new code to the repository. For that we need to create a job file.

The job file defines all the jobs which can be run by runners registered for the repository. The first section of the yaml defines the stages where jobs run. At each stage, job run concurrently when multiple runners are registered. The order of execution respects the order we define in the yaml.

In the following example, we will define three stages `build`, `deploy` and `clean`.

```yml
stages:
  - build
  - deploy
  - clean
```

Next we can define the job themselves. The complete documentation of a job is on [Gitlab documentation](https://docs.gitlab.com/ee/ci/yaml/).

We start by specifying the build which will be done in build stage.

```yml
build:
  stage: build
  script:
    - /usr/bin/dotnet publish -c Release
  only:
    - master
  variables:
    GIT_STRATEGY: fetch
  tags:
    - myapp
```

`script` allows us to specify an array of shell commands to run synchronously.
`only` defines for which branch the job should be triggered.
`tags` defines which runner will be targeted to run the job.
`variables` defines an object composed of variables available during the job. The variables can be custom for our own use and can be variables used to setup settings on the job itself. Here we set the `GIT_STRATEGY` to `fetch` which order the job to fetch the repository. Other settings are available and can be found in the documentation.

After we built, we can deploy the application. Following the same job properties as the build, we set a script command to run a shell script present in our source code.

```
deploy:
  stage: deploy
  script:
    - chmod 774 $CI_PROJECT_DIR/deploy.sh
    - SERVICES=( Service1 Service2 )
    - for i in "${SERVICES[@]}"; do $CI_PROJECT_DIR/deploy.sh $i; done
  variables:
    GIT_STRATEGY: none
  only:
    - master
  tags:
    - myapp
```

`$CI_PROJECT_DIR` is set to the path to the source code fetched by the runner. The first step is to allow execution of the deployment script with `chmod 774 $CI_PROJECT_DIR/deploy.sh`.
Next we simply run it by specifying all the projects to deploy using an array and a `for in` loop.

```sh
- SERVICES=( Service1 Service2 )
    - for i in "${SERVICES[@]}"; do $CI_PROJECT_DIR/deploy.sh $i; done
```

We can also see that we have set the `GIT_STRATEGY` to none which prevents the runner from fetching the solution again.

The deployment script is as followed:

```sh
#!/bin/bash -v

set -e

if [ -z $1 ]; then
    echo "Argument cannot be empty."
    exit
fi

APP_NAME=$(echo $1 | awk '{print tolower($0)}') 
APP_DIR=/usr/share/myapp/$APP_NAME
ZIP=myapp-$APP_NAME.zip

# create temp folder for preparing zip
mkdir -p ~/myapp/$APP_NAME

# move published output from build stage to folder
mv $CI_PROJECT_DIR/MyApp.$1/bin/Release/netcoreapp2.0/publish/* ~/myapp/$APP_NAME

# navigate to folder to set root for zip
cd ~/myapp

# zip folder
zip -r ~/$ZIP $APP_NAME

# copy zip to server
scp -qr ~/$ZIP myserver:~/

# ssh to server and unzip within server to temp folder
ssh myserver "unzip -o $ZIP -d ~/myapp"

# ssh to server and remove app folder and content
ssh myserver "sudo rm -rf $APP_DIR/*"

# ssh to server and copy binaries from temp folder to app folder
ssh myserver"sudo cp -r ~/ek/$APP_NAME/* $APP_DIR"

# ssh to server and set user and group to user used by nginx and systemd
ssh myserver "sudo chown -R www-data:www-data $APP_DIR/*"

# ssh to server and restart systemd unit
ssh myserver "sudo systemctl restart myapp-$APP_NAME"
```

Last stage is to clean the temporary folder created during zip and unzip.

```
clean:
  stage: clean
  script:
    - rm -r ~/ek*
    - ssh myserver "rm -r ek*"
  variables:
    GIT_STRATEGY: none
  only:
    - master
  when: always
  tags:
    - myapp
```

`when: always` is a variable used to define when is the job run where `always` means that thd job will run regardless the state of the previous stage hence if `deploy` succeeds or fails, `clean` will run.