
# Kaniko

Provides methods for building Docker containers using Kaniko.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/kaniko@0.0.5", "kaniko")
```


### kaniko(task_name, git_name, image_repo, tag, context, dockerfile, build_args, inputs, outputs, steps, **kwargs)


Build a Docker image using Kaniko.



