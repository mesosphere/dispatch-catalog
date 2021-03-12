
# Buildkit

Provides methods for interacting with a Buildkit instance.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/buildkit@0.0.7", "buildkit")
```


### buildkit_container(name, image, workingDir, command, env, input_paths, output_paths, volumeMounts, **kwargs)


buildkit_container returns a Kubernetes corev1.Container that runs inside of buildkit.
The container can take advantage of buildkit's cache mount feature as the cache is mounted into /cache.
Callers _must_ have all volumes returned by buildkit_volumes in the pod of the container.
This method is generally intended to be imported by other catalog tasks and not used directly.


### buildkit_volumes()


buildkit_volumes returns a list of Kubernetes corev1.Volumes and corev1.VolumeMounts required by buildkit_container,
which includes the `buildkit-client-cert` secret volume to be mounted in buildkit containers.


### buildkit(task_name, git_name, image_repo, tag, context, dockerfile, working_dir, build_args, build_env, env, inputs, outputs, steps, volumes, **kwargs)


Build a Docker image using Buildkit.



