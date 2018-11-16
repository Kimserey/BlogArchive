# Shared libraries and DSL in Jenkins

When we have multiple pipelines in Jenkins, it becomes necessary to share code between them. For example, we might want to have a stage that we want to setup for a different environment therefore the only change needed would be its parameters. Today we will see how we can provide reusable functionalities in Jenkins pipeline across a single or multiple pipelines. 

1. Setup a reusable groovy component
2. Setup a shared library in Jenkins
3. Use shared library in Jenkins pipeline 

For this post I will be using the [local setup Jenkins + Git repository](https://kimsereyblog.blogspot.com/2018/10/setup-jenkins-pipeline-for-local.html) I have explained in my previous blog post therefore the repository URLs are all local.

## 1. Setup a reusable groovy component

We start by setting up a git repository with the following structure:

```
/jenkins-shared
 - /vars
    - logs.groovy
```



```
// /jenkins-shared/var/logs.groovy

def info(message) {
    echo "INFO: ${message}"
}

def warning(message) {
    echo "WARNING: ${message}"
}

def call(body) {
    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    println config

    switch (config.type) {
       case 'info':
          info config.message
          break
      case 'warning':
          warning config.message
          break
       default:
          error "Unhandled type."
    }
}
```

## 2. Setup a shared library in Jenkins

## 3. Use shared library in Jenkins pipeline 

```
@Library('my-shared-library') _

properties([
  parameters([
    string(name: 'MESSAGE', defaultValue: 'HEY HEY', description: 'Some message')
   ])
])


stage ("Shared Library Test") {
  
  log.info "test info!"
  
  log {
    type = "warning"
    message = "test warning closure!"
  }

  def msg = params.MESSAGE

  log {
    type = "info"
    message = msg
  }
}
```