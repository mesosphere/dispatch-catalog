
# Buildkit

Provides methods for interacting with a Buildkit instance.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/buildkit@0.0.5", "buildkit")
```


### buildkit(task_name, git_name, image_repo, tag, context, dockerfile, build_args, build_env, inputs, outputs, steps, volumes, **kwargs)


Build a Docker image using Buildkit.


### buildkit_container(name, image, workingDir, command, output_paths, **kwargs)


buildkit_container returns a Kubernetes corev1.Container that runs inside of buildkit.
The container can take advantage of buildkit's cache mount feature as the cache is mounted into /cache.



