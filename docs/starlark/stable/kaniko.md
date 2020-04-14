
# Kaniko

Provides methods for building Docker containers using Kaniko.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/kaniko@0.0.4", "kaniko")
```


### kaniko(git, image, context, dockerfile, **kwargs)


Build a Docker image using Kaniko.



