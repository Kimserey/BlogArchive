# Setup a Jenkins local development environment via Docker container

CI/CD pipelines allow us to automatically build, test and deploy code changes. With [Jenkins pipeline](https://jenkins.io/doc/book/pipeline/), the pipeline itself is generated from a file called the Jenkinsfile which, usually, is source controlled together with the source code repository. When we need to push new changes, what we would usually do, is test locally and then commit to the repository. From there, the Jenkins pipeline will trigger and build, test on the integration server and deploy to a testable environment (DEV/QA). But what do we do when the changes that we are making are on the Jenkinsfile itself? How do we test locally the validity of the Jenkinsfile or more simply, how do we try on a sandbox a Jenkins pipeline to learn how to write a Jenkinsfile? Today we will see how we can setup a sandbox with a full CI/CD deployment which can be quickly brought up and teared down for testing.

1. Jenkins server via docker
2. Jenkins pipeline
3. Simulate deployment to server

## 1. Jenkins server via docker

```
FROM jenkins/jenkins:lts
USER root

# Install .NET CLI dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        liblttng-ust0 \
        libssl1.0.2 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 2.1.403

RUN curl -SL --output dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='903a8a633aea9211ba36232a2decb3b34a59bb62bc145a0e7a90ca46dd37bb6c2da02bcbe2c50c17e08cdff8e48605c0f990786faf1f06be1ea4a4d373beb8a9' \
    && sha512sum dotnet.tar.gz \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Configure Kestrel web server to bind to port 80 when present
ENV ASPNETCORE_URLS=http://+:80 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip

# Trigger first run experience by running arbitrary cmd to populate local package cache
RUN dotnet help
```

`.dockerignore` to not send the whole folder as context.

```
.vscode
jenkins_home
```

```
docker build -f .\Dockerfile -t jenkins-test .
 
if not exist "C:\Projects\jenkins-pipeline-test\jenkins_home" mkdir C:\Projects\jenkins-pipeline-test\jenkins_home

docker run -p 8080:8080 -p 50000:50000 ^
    -v C:/Projects/jenkins-pipeline-test/jenkins_home:/var/jenkins_home ^
    -v C:/Projects:/var/projects ^
    -v /var/run/docker.sock:/var/run/docker.sock ^
    --name jenkins-test jenkins-test
```

```
docker container rm -f jenkins-test

docker image rm jenkins-test
```

## 2. Jenkins pipeline

`file:///var/projects/HelloWorldJenkins/`

`post-commit` in `.git/hooks/`.

```
curl -u kimserey:12345 http://localhost:8080/job/TestPipeline/build?token=mytoken
```

## 3. Simulate deployment to server

`-v /var/run/docker.sock:/var/run/docker.sock`

```
curl --unix-socket /var/run/docker.sock \
    -X POST -H "Content-Type:application/x-tar" \
    --data-binary '@artifact.tar' \
    http:/v1.38/build?t=hello-world-jenkins
```

```
curl --unix-socket /var/run/docker.sock \
    -X DELETE \
    http:/v1.38/containers/hello-world-jenkins?force=1
```

```
curl --unix-socket /var/run/docker.sock \
    -H "Content-Type: application/json" \
    -d @create-container.json \
    -X POST \
    http:/v1.38/containers/create?name=hello-world-jenkins
```

```
curl --unix-socket /var/run/docker.sock -X POST http:/v1.24/containers/hello-world-jenkins/start
```

```
pipeline {
    agent any

	options {
		skipDefaultCheckout true
	}

	stages {
        stage('checkout') {
            steps {
                checkout scm
            }
        }

        stage('build') {
			steps {
				sh "dotnet build src/HelloWorldJenkins"
			}
        }

        stage('test') {
			steps {
				sh "dotnet test test/HelloWorldJenkins.UnitTests"
			}
        }

		stage('build docker image') {
			steps {
				sh "dotnet clean"

				sh "touch artifact.tar"

				sh "tar --exclude=artifact.tar --exclude=.git* --exclude=./test* --exclude=.vs* -cvf artifact.tar ."

				sh	"""
					curl --unix-socket /var/run/docker.sock \
						-X POST -H "Content-Type:application/x-tar" \
						--data-binary '@artifact.tar' \
						http:/v1.38/build?t=hello-world-jenkins
				"""
			}
		}

		stage('teardown old container') {
			steps {
				sh """
					curl --unix-socket /var/run/docker.sock \
						-X DELETE \
						http:/v1.38/containers/hello-world-jenkins?force=1
				"""
			}
		}

        stage('deploy new container') {
			steps {
				sh """
					curl --unix-socket /var/run/docker.sock \
						-H "Content-Type: application/json" \
						-d @create-container.json \
						-X POST \
						http:/v1.38/containers/create?name=hello-world-jenkins
				"""

				sh "curl --unix-socket /var/run/docker.sock -X POST http:/v1.24/containers/hello-world-jenkins/start"
			}
        }
    }
}
```