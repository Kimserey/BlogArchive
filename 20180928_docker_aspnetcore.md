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


### If Docker is not starting

Check that Hypervisor is enabled by opening the `Windows Features` and check if every checkbox is selected under `Hyper-V`.

![windowsfeatures]()

Next Under Hyper-V Manager check that `MobyLinuxVM` is in `Running` state.

![hypervmanager]()

If it isn't running, Docker fails to start, virtualization might not be enable on your computer and you will have to enable it on BIOS.

![bios]()

## 2. Docker basic commands

docker image ls
docker container ls
docker container stop [container id]
docker container prune
docker rmi [image id]
docker image prune
docker build
docker run

## 3. Create ASP NET Core application

dotnetcoreapp
docker-compose project
docker-compose

Test test


