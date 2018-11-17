# Shared libraries and DSL in Jenkins

When we have multiple pipelines in Jenkins, it becomes necessary to share code between them. For example, we might want to have a stage that we want to setup for a different environment therefore the only change needed would be its parameters. Today we will see how we can provide reusable functionalities in Jenkins pipeline across a single or multiple pipelines. 

1. Setup a reusable groovy component
2. Setup a shared library in Jenkins
3. Use shared library in Jenkins pipeline 

For this post I will be using the [local setup Jenkins + Git repository](https://kimsereyblog.blogspot.com/2018/10/setup-jenkins-pipeline-for-local.html) I have explained in my previous blog post therefore the repository URLs are all local.

## 1. Setup a reusable groovy component

In this example we will be providing a reusable component which provides a log functionality. This is how it will look like when using it in a pipeline:

```
log {
  type = "warning"
  message = "test warning closure!"
}
```

What we want to achieve is a DSL implementation with a single `log {}` element. 
This functionality will be available across all pipelines therefore we will be able to use it everywhere we need it.
_This is actually how Jenkins pipeline is built itself with `node {}`, `stage {}`, etc.._

We start by setting up a git repository with the following structure:

```
/jenkins-shared
 - /vars
    - logs.groovy
```

We then create the content of the `logs.groovy` file.

```
def log_info(message) {
    echo "INFO: ${message}"
}

def log_warning(message) {
    echo "WARNING: ${message}"
}

def log_error(message) {
    echo "ERROR: ${message}"
}

def call(body) {
    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    switch (config.type) {
      case 'info':
        log_info config.message
        break
      case 'warning':
        log_warning config.message
        break
      case 'error':
        log_error config.message
        break
      default:
        error "Unhandled type."
    }
}
```

The function `call` is a special function in groovy that can be called without going `.call ()`. We use it in order to be able to call `logs {}` without the need of going `logs.call {}`. The `body` parameter is expected to be a [closure](http://groovy-lang.org/closures.html) which will set values in the closure to the config. This allow the following notation to set the values on the map config.

```
{
  type = "warning"
  message = "test warning closure!"
}
```

Line by line, we create an empty map which will hold the configuration, then we set the strategy of the closure to resolve the delegate first and set the delegate to be the configuration. This allows the closure to sets values on the `config` instead of setting the current class. Lastly we execute the closure `body()`.

```
def config = [:]
body.resolveStrategy = Closure.DELEGATE_FIRST
body.delegate = config
body()
```

To understand better what `Closure.DELEGATE_FIRST` mean, take a look at the following:

```
def config = [:]
def body = {
  type = "warning"
  message = "test warning closure!"
}
body.resolveStrategy = Closure.DELEGATE_FIRST
body.delegate = config
body()

println "config:" + config.message
println "this:" + this.message
```

If we execute this on [an online groovy compiler](https://www.jdoodle.com/execute-groovy-online), we will see that when we set `Closure.DELEGATE_FIRST`, the `message` is present on the config, while when we remove it, the `message` is present on the current class `this` instead. 

We now have a class that can be used on its own with the notation we wanted:

```
log {
  type = "warning"
  message = "test warning closure!"
}
```

### Limitations

There are limitations to be aware of, the first one being that if you are using parameters for your pipeline, the `params` will not be available within the closure therefore the following will not work:

```
log {
  type = "warning"
  message = params.MESSAGE // <= this will throw null exception
}
```

Another limitation is that it's not possible to use the same name as the property itself as it will result in null. For example the following will not work:

```
def message = "My Message"

log {
  type = "warning"
  message = message // <= this will be null
}
```

Now let's see how we can make it available in Jenkins pipeline.

## 2. Setup a shared library in Jenkins

To make our functionality available in Jenkins pipelines, we need to setup Jenkins to recognize our repository as a shared library.

![]()

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