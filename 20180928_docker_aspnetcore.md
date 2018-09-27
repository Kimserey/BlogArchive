# Deploy ASP NET Core application on Docker Linux container from Windows

Few weeks ago we saw how we could run [ASP NET Core application on Ubuntu](https://kimsereyblog.blogspot.com/2018/06/asp-net-core-with-nginx.html). This proving that a .NET Core Application can run on a Linux system, today we will be taking it a step further and see how we can deploy our application in a Docker Linux container. This post will be composed by three parts:

1. Install Docker on Windows
2. Docker basic commands
3. Create ASP NET Core application

## 1. Install Docker on Windows

The first step is to go to the [official site, sign up and download Docker CE](https://store.docker.com/editions/community/docker-ce-desktop-windows).
Once downloaded, install Docker.

After being installed you should be able to right click on the icon > Settings on the Docker notification icon and see that Docker is running by checking the status at the bottom left, it should say `Docker is running`.

Open `PowerShell` and type `docker run hello-world`.

```
$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
d1725b59e92d: Pull complete
Digest: sha256:0add3ace90ecb4adbf7777e9aacf18357296e799f81cabc9fde470971e499788
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
```

You just downloaded the `hello-world` image and ran it in a container which printed `Hello from Docker` which was redirected to the console.

Useful link to the Docker orientation [https://docs.docker.com/get-started/#prepare-your-docker-environment](https://docs.docker.com/get-started/#prepare-your-docker-environment)


### Fix Docker not starting:

 - Check that Hypervisor is enabled by opening the `Windows Features` and check if every checkbox is selected under `Hyper-V`.
 
 ![windowsfeatures](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20180929_docker/docker_2.PNG)

- Next Under Hyper-V Manager check that `MobyLinuxVM` is in `Running` state.

![hypervmanager](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20180929_docker/docker_1.PNG)

- If it isn't running, Docker fails to start, virtualization might not be enable on your computer and you will have to enable it on BIOS.

![bios](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20180929_docker/docker_3.jpeg)

## 2. Docker basic commands

Now that Docker is installed and we can start build images and running containers, we can look into some of the terminology and [commands from the CLI](https://docs.docker.com/engine/reference/commandline/cli/).

An image is a set of layers describe by the `Dockerfile`. It represents a state of an environment. It is built with `docker build`. There can be multiple version of the image tagged to different versions. A container is a running instance of an image bootup using `docker run`. Multiple containers can be started from the same image.

To manage image and containers, we can use the commnad `docker image ...` and `docker container ...`.

For example to list all the containers running:

```
docker container ls
```

Or to see all images:

```
docker image ls
```

A container can be seen as a running process, it can be stopped using the following command:

```
docker container stop [container-id]
```

Or killed:

```
docker container kill [container-id]
```

Rogue images and containers can be cleared with `prune`, `docker image/container prune`.
And lastly images and containers can be removed using `rm` with `docker image/container rm [image or container id]`.

Now that we have Docker installed, and know some functionalities of the `docker CLI`, let's see how we can setup an ASP NET Core application running in Docker Linux container.

## 3. Create ASP NET Core application

docker-compose project
docker-compose

Test test


