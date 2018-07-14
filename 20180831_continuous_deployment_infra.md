# Continuously deploy infrastructure with Gitlab Pipeline

Few weeks ago we saw how we could [Setup continious integration and deployment to deploy an application using Gitlab Pipeline](https://kimsereyblog.blogspot.com/2018/06/setup-cicd-pipeline-with-gitlab-for.html). We configured a service with `systemd` and had an ASP NET Core application automatically deployed when code was pushed to the repository. This automation allows us to reduce interaction with the server and reducing the manual work. The "infrastructure" configurations like `systemd` service files and `nginx` site files must also be created or edited on the server therefore it makes sense to also have them automatically deployed. On top of that, it makes even more sense to have them save in repository and source controlled. Today we will see how we can leverage Gitlab Pipeline to setup a continuous deployment for our infrastructure files in three parts:

1. Setup the repository
2. Setup the runner job
3. Deploy the configurations

## 1. Setup the repository

We start first by creating a repository with the same structure as our server. For example, if we have two different configuration systemd and nginx to be deployed on Ubuntu 16.04, we will have the following structure:

```txt
/my-infrastructure-repo
- /systemd
    - /system
        - myapp.service
        - myapp2.service
- /nginx
    - /sites-available
        - myapp.com
        - myapp2.com
- deploy.sh
- .gitlab-ci.yml
```

_If you are not familiar with Gitlab Pipeline and ASP NET Core deployment onto Ubuntu, you can refer to my previous post on [How to setup CICD for ASP NET Core with Gitlab Pipeline](https://kimsereyblog.blogspot.com/2018/06/setup-cicd-pipeline-with-gitlab-for.html)._

As we can see the structure of our files follows the structure of the files on the server. The service file of systemd would be for example a unit which we configure to run ASP NET Core:

```txt
[Unit]
Description=My app

[Service]
WorkingDirectory=/usr/share/app/myapp
ExecStart=/usr/bin/dotnet /usr/share/app/myapp/MyApp.dll
SyslogIdentifier=app-myapp
User=www-data

[Install]
WantedBy=multi-user.target
```

And the nginx file would be a site file configuration:

```txt
upstream myapp {
    server localhost:5000;
}

server {
    listen 80;
    listen [::]:80;
    server_name myapp.com www.myapp.com;

    location / {
        include /etc/nginx/proxy_params;
        proxy_http_version 1.1;
        proxy_set_header Connection keep-alive;
        proxy_set_header Upgrade $http_upgrade;
        proxy_cache_bypass $http_upgrade;
        proxy_pass http://myapp/;
    }
}
```

What we end up with is a repository containing all the configurations for our infrastructure. This allows us to source control all files and revert changes when necessary. Next we move on to setup the Gitlab runner job.

## 2. Setup the runner job

Here we assume that we already have setup a CI server containing our runner. We also assume that the runner has ssh access to the application server to deploy files to it.

_If you aren't familiar with Gitlab runner, refer to my [previous post explaning how to setup a runner](https://kimsereyblog.blogspot.com/2018/06/setup-cicd-pipeline-with-gitlab-for.html) or if you aren't familiar with ssh, refer to my [previous post explaining how to configure ssh](https://kimsereyblog.blogspot.com/2018/05/useful-bash-and-friends-commands.html)._

The `.gitlab-ci.yml` file defines how the runner execute the jobs.

```yml
stages:
  - deploy
  - clean

deploy:
  stage: deploy
  script:
    - chmod 755 $CI_PROJECT_DIR/deploy.sh
    - $CI_PROJECT_DIR/deploy.sh
  variables:
    GIT_STRATEGY: fetch
  only:
    - master
  tags:
    - infra

clean:
  stage: clean
  script:
    - ssh husky "rm -r myapp-infrastructure-*"
  variables:
    GIT_STRATEGY: none
  only:
    - master
  when: always
  tags:
    - infra
```

Here we setup two jobs, `deploy` and `clean`. `deploy` will push the files to the server on a temporary folder `myapp-infrastructure-xxx`, depending on what we are pushing, before replacing the root files. Because the whole repository is present on the CI server, we can make use of our deployment script `deploy.sh`. We make sure to change first the permissions to be able to execute it.

```yml
script:
    - chmod 755 $CI_PROJECT_DIR/deploy.sh
    - $CI_PROJECT_DIR/deploy.sh
```

Then `clean` will remove the temporary folder(s) `myapp-infrastructure-*`.

```yml
script:
    - ssh husky "rm -r myapp-infrastructure-*"
```

We now have our runner job setup, and Gitlab will run the `deploy` job and `clean` job everytime we push a change on the infrastructure repository. What we have left to do is to write the `deploy.sh` script.

## 3. Deploy the configurations

```sh
#!/bin/bash -v
set -e

echo "[systemd] Copy over units to husky."
rsync -crlDz $CI_PROJECT_DIR/systemd/ husky:~/ek-infrastructure-systemd/

echo "[systemd] Sync configurations with /etc/systemd/ folder."
RESULT="$(ssh husky "sudo rsync -crlDi ~/ek-infrastructure-systemd/ /etc/systemd/")"

if [ -n "$RESULT" ]; then
        echo "[systemd] Updated files:"
        echo "$RESULT"
        echo "[systemd] Reloading systemd."
        ssh husky "sudo systemctl daemon-reload"
else
        echo "[systemd] Nothing has changed."
fi
```
