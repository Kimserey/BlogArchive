# Continuously deploy infrastructure with Gitlab Pipeline

Few weeks ago we saw how we could [Setup continious integration and deployment to deploy an application using Gitlab Pipeline](https://kimsereyblog.blogspot.com/2018/06/setup-cicd-pipeline-with-gitlab-for.html). We configured a service with `systemd` and had an ASP NET Core application automatically deployed when code was pushed to the repository. This automation allows us to reduce interaction with the server and reducing the manual work. The "infrastructure" configurations like `systemd` service files and `nginx` site files must also be created or edited on the server therefore it makes sense to also have them automatically deployed. On top of that, it makes even more sense to have them save in repository and source controlled. Today we will see how we can leverage Gitlab Pipeline to setup a continuous deployment for our infrastructure files in three parts:

1. Automate Systemd configuration deployment
2. Automate Nginx configuration deployment 
3. Automate Cloudwatch configuration deployment

## 1. Automate Systemd configuration deployment