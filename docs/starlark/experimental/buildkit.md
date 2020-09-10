
# Buildkit

Provides methods for interacting with a Buildkit instance.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/buildkit@0.0.7", "buildkit")
```


### buildkit_container(name, image, workingDir, command, output_paths, volumeMounts, **kwargs)


buildkit_container returns a Kubernetes corev1.Container that runs inside of buildkit.
The container can take advantage of buildkit's cache mount feature as the cache is mounted into /cache.
Callers _must_ have the `buildkit-client-cert` secret volume available to the container as a volume called `certs`. This method is generally intended to be imported by other catalog tasks and not used directly.


### buildkit(task_name, git_name, image_repo, tag, context, dockerfile, working_dir, build_args, build_env, env, inputs, outputs, steps, volumes, **kwargs)


Build a Docker image using Buildkit.



