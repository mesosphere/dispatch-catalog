
# Buildkit

Provides methods for interacting with a Buildkit instance.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/buildkit@0.0.5", "buildkit")
```


### buildkit(task_name, git_name, image_repo, tag, context, dockerfile, build_args, build_env, inputs, outputs, steps, volumes, **kwargs)


Build a Docker image using Buildkit.


### buildkit_container(name, image, workingDir, command, output_paths, cert_volume_name, volumeMounts, **kwargs)


buildkit_container returns a Kubernetes corev1.Container that runs inside of buildkit.
The container can take advantage of buildkit's cache mount feature as the cache is mounted into /cache.

In order to connect to a buildkit instance, `buildkit_container` requires the name of the buildkit certificate
volume so that it can be added to the container created.

Example usage:

```
task("my-task", inputs=[git], steps=[buildkit_container(
    name="go-test",
    image="golang:1.14",
    command=["go", "test", "-v", "./pkg/..."]
    env=[k8s.corev1.EnvVar(name="GO111MODULE", value="on")],
    workingDir=git_checkout_dir(git),
)], volumes=[
    k8s.corev1.Volume(name = "cert", volumeSource = secret_volume("buildkit-client-cert"))
])
```



