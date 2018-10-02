# Docker compose an ASP NET Core application with SQL Server

Last week we saw how we could install and run [an ASP NET Core application in a container](https://kimsereyblog.blogspot.com/2018/09/deploy-asp-net-core-application-on.html), we saw how Visual Studio uses `docker-compose` to setup our services. Today we will see how we can use `compose` to setup a cluster composed by an ASP NET Core application container with a SQL Server container and how we can place in a third party process. This post will be composed by three parts:

1. Setup SQL Server container on its own
2. Setup an ASP NET Core application with SQL Server
3. Setup a Flyway as migration tool

## 1. Setup SQL Server container on its own

$ On local machine  > docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=MyPassword001" -p 1433:1433 --name sql1 -d mcr.microsoft.com/mssql/server:2017-latest

$ On local machine  > docker exec -it sql1 bash

$ On sql1 container > /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P MyPassword001

$ On local machine  > sqlcmd -S localhost,1433 -U SA -P MyPassword001
$ use testdb
$ select * from inventory;
$ go


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