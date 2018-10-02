# Docker compose an ASP NET Core application with SQL Server

Last week we saw how we could install and run [an ASP NET Core application in a container](https://kimsereyblog.blogspot.com/2018/09/deploy-asp-net-core-application-on.html), we saw how Visual Studio uses `docker-compose` to setup our services. Today we will see how we can use `compose` to setup a cluster composed by an ASP NET Core application container with a SQL Server container and how we can place in a third party process. This post will be composed by three parts:

1. Setup SQL Server container on its own
2. Setup an ASP NET Core application with SQL Server
3. Setup a Flyway as migration tool

## 1. Setup SQL Server container on its own

If you haven't installed Docker, [follow my previous blog post]().

The SQL Server Docker image can be downloaded from `mcr.microsoft.com/mssql/server:2017-latest`. So first we can start by running the container:

```
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=MyPassword001" -p 1433:1433 --name sqlserver-test -d mcr.microsoft.com/mssql/server:2017-latest
```

- `-e` specifies an environment variable, here we specify password and acceptance of EULA (end user license agreement),
- `-p` specifies the port to forward so that we can connect from the host (our local machine),
- `--name` specifies the name used to identify the container - this is useful to start/stop/delete the container,
- `-d` specifies that we want to start a detached container (runs in background).

Once we run this command, we can check that the container is running:

```
> docker container ls
CONTAINER ID        IMAGE                                        COMMAND                  CREATED             STATUS              PORTS                    NAMES
3ac875159441        mcr.microsoft.com/mssql/server:2017-latest   "/opt/mssql/bin/sqls…"   6 seconds ago       Up 5 seconds        0.0.0.0:1433->1433/tcp   sqlserver-test
```

_If you face an error like `input/output error`, restart Docker._

Once SQL Server is running, we can get a `bash` prompt by using the following command:

```
> docker container exec -it sqlserver-test bash
root@3ac875159441:/#
```

Then we can enter the interactive SQL command prompt by using the user SA and the password we specified:

```
root@3ac875159441:/# /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P MyPassword001
1>
```

Next we can execute a SQL command:

```
1> CREATE DATABASE mydb
2> GO
1> USE mydb
2> GO
Changed database context to 'mydb'.
```

Then insert data into it:

```
1> CREATE TABLE person (id INT, name VARCHAR(255), primary key (id));
2> GO

1> insert into person values (1, 'kim');
2> GO
(1 rows affected)

1> insert into person values (2, 'tom');
2> GO
(1 rows affected)
```

Lastely query from it:

```
1> SELECT * from person
2> GO
id   name
  1  kim
  2  tom
(2 rows affected)
```

We endup with a fully working SQL Server running in a container. If we were to use SQL Server Management studio (SSMS), we would be able to connect to `localhost,1433` and browse our databse.

![SSMS]()

Now that we know how SQL Server works, we can delete this container which will permanently destroy all data in the database.

```
docker container stop sqlserver-test
docker container rm sqlserver-test
```

## 2. Setup an ASP NET Core application with SQL Server

```
services:
  webapplication1:
    build:
      context: .
      dockerfile: WebApplication1/Dockerfile
    depends_on:
      - db
      - migration
  migration:
    build:
      context: .
      dockerfile: Migrations/Dockerfile
    environment:
        SA_USER: "sa"
        SA_PASSWORD: "MyPassword001"
    depends_on:
      - db
  db:
    image: "mcr.microsoft.com/mssql/server"
    environment:
        SA_PASSWORD: "MyPassword001"
        ACCEPT_EULA: "Y"
    ports:
      - "1433:1433"
```


```
FROM boxfuse/flyway
WORKDIR /src
COPY Migrations/sql .
ENTRYPOINT flyway migrate -user=$SA_USER -password=$SA_PASSWORD -url="jdbc:sqlserver://db:1433;databaseName=master" -locations="filesystem:."
```

Check if migration ran:
docker logs dockercompose17122146709022121950_migration_1

## 3. Setup a Flyway as migration tool