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
    - ssh appserver "rm -r myapp-infrastructure-*"
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
    - ssh appserver "rm -r myapp-infrastructure-*"
```

We now have our runner job setup, and Gitlab will run the `deploy` job and `clean` job everytime we push a change on the infrastructure repository. What we have left to do is to write the `deploy.sh` script.

## 3. Deploy the configurations

The `deploy.sh` script will push the latest files from the CI server to the Application server. Then once pushed, will update the original files and restart/reload the service if required.

```sh
#!/bin/bash -v
set -e

echo "[systemd] Copy over units to appserver."
rsync -crlDz $CI_PROJECT_DIR/systemd/ appserver:~/myapp-infrastructure-systemd/

echo "[systemd] Sync configurations with /etc/systemd/ folder."
RESULT="$(ssh appserver "sudo rsync -crlDi ~/myapp-infrastructure-systemd/ /etc/systemd/")"

if [ -n "$RESULT" ]; then
        echo "[systemd] Updated files:"
        echo "$RESULT"
        echo "[systemd] Reloading systemd."
        ssh appserver "sudo systemctl daemon-reload"
else
        echo "[systemd] Nothing has changed."
fi
```

We start first by using `rsync` to sync our file to the `appserver` on a temporary folder `myapp-infrastructure-systemd`. We assume here that we have configure ssh to connect to `appserver` with `ssh appserver`. 

```sh
echo "[systemd] Copy over units to appserver."
rsync -crlDz $CI_PROJECT_DIR/systemd/ appserver:~/myapp-infrastructure-systemd/
```

 - `-c` option is used to check file with checksum,
 - `-r` is for recursive
 - `-l` and `-D` are to copy symlink and preserve device and special files
 - `-z` is to compress files

Once we have the file onto the temporary location, we execute a remote `rsync` to replace the original files:

```sh
echo "[systemd] Sync configurations with /etc/systemd/ folder."
RESULT="$(ssh appserver "sudo rsync -crlDi ~/myapp-infrastructure-systemd/ /etc/systemd/")"
```

 - `-i` option allows us to get back a summary of each changes done by `rsync`

The result of `rsync` is then saved in a variable `$RESULT` which we use to decide whether we should restart the service or not.

```sh
if [ -n "$RESULT" ]; then
        echo "[systemd] Updated files:"
        echo "$RESULT"
        echo "[systemd] Reloading systemd."
        ssh appserver "sudo systemctl daemon-reload"
else
        echo "[systemd] Nothing has changed."
fi
```

 - `-n` check for `null` string and returns true if the string is not null

When a result is returned by `rsync`, we know that one of the service file from `systemd` has changed therefore we can execute a remote ssh command to reload `systemd` with `ssh appserver "sudo systemctl daemon-reload"`.

Following the same example, we can setup the same deployment for nginx sites files. Here is a full example of the `deploy.sh` script:

```sh
#!/bin/bash -v
set -e

echo "[nginx] Copy over configurations to appserver."
rsync -crlDz $CI_PROJECT_DIR/nginx/ appserver:~/myapp-infrastructure-nginx/

echo "[nginx] Sync configurations with /etc/nginx/ folder."
RESULT="$(ssh appserver "sudo rsync -crlDi ~/myapp-infrastructure-nginx/ /etc/nginx/")"

if [ -n "$RESULT" ]; then
        echo "[nginx] Updated files:"
        echo "$RESULT"
        ssh appserver "sudo nginx -t"

        echo "[nginx] Reloading nginx."
        ssh appserver "sudo service nginx reload"
else
        echo "[nginx] Nothing has changed."
fi

echo "[systemd] Copy over units to appserver."
rsync -crlDz $CI_PROJECT_DIR/systemd/ appserver:~/myapp-infrastructure-systemd/

echo "[systemd] Sync configurations with /etc/systemd/ folder."
RESULT="$(ssh appserver "sudo rsync -crlDi ~/myapp-infrastructure-systemd/ /etc/systemd/")"

if [ -n "$RESULT" ]; then
        echo "[systemd] Updated files:"
        echo "$RESULT"
        echo "[systemd] Reloading systemd."
        ssh appserver "sudo systemctl daemon-reload"
else
        echo "[systemd] Nothing has changed."
fi
```

And that concludes today's post. We should now have a fully automated deployment of a infrastructure files. Everytime we push any changes on the configuration files, the runner will pick them up and deploy it to our application server and restart the appropriate service either `systemd` or `nginx`.

## Conclusion

Today we saw how we could setup a continuous deployment of infrastructure files in the same way as we did for our application code. We started by setting up a repository for our infrastructure files, then moved to configure the runner jobs and finally wrote a deployment script files used by the job to deploy the files to the application server and restart the appropriate services. Hope you liked this post, see you next time!