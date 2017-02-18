# Configuration files for your WebSharper sitelet in F#

Configurations are an important part of a project. Just last week I explained how we can implement a Jwt auth for WebSharper sitelet and we needed to provide a private key and token lifespans. As a simple rule, we should avoid hardcoding configurations. The value is that at runtime we can swap different configurations and therefore have multiple configurations files for different scenarios.
Today I will show how we can create a json configuration file and pas it around our sitelet.
This post will be composed by two parts.

1. Create the configuration and use it in a WebSharper sitelet scenario
2. Handling multiple configurations
3. Handle CLI arguments

1. Create the configuration and use it in a WebSharper sitelet scenario

In WebSharper when we create a selfhost we directly have some code extracting url and root directory from the arguments.
Instead of providing those arguments to the CLI we can put all the configurations in a structured configurations file.

We start by defining a configuration type:

Type Configurations

Then we make a json implementation of that configurations file.

Code

Next before we start our sitelet, we can deserialise the json content into the typed Configurations and pass it to our sitelet.

Code

2. Handle multiple configurations

We often need to have multiple set of configurations. A typical scenario is to have a one configurations file for each development phase, dev, test and live.

With the json Config file we can easily achieve that by adding a postfix with the instance.

Config-dev.json
Config-test.json
Config-live.json

And make the user only specify which instance via CLI argument. To prevent mistakes, we can default to dev when no argument is provided.

Code

3. Handle CLI arguments

The json config gives us configurations specific to the application. If we need to handle more higher level configs, it can be useful to pass it as CLI arguments.

We already pass the instance to find the correct config file, another argument which we can pass could be the log level desired.

To do that we need to define a protocol to recognise arguments. For example we could use:

Myapp.exe -instance=dev -loglevel=warning

Which would mean start with dev config and only show warnings and above.

To handle that we will recursively parse the command line arguments:

Code

Doing it this way allows us to not be affected by the arguments order.

And that's it! An easy way to configure your application.

# Conclusion

Today we saw how we can use json configurations file to hold configuration for different instances of the same application. We also saw how we could parse CLI arguments without caring about the order.
I hope you liked this post, if you have any comment leave it here or hit me on Twitter [@Kimserey_Lam](). See you next time!
