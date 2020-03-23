
# Buildkit

Provides methods for interacting with a Buildkit instance.

Import URL: `github.com/mesosphere/dispatch-catalog/starlark/experimental/buildkit`

### buildkitContainer(name, image, workingDir, command, output, **kwargs)


buildkitContainer returns a Kubernetes corev1.Container that runs inside of buildkit.
The container can take advantage of buildkit's cache mount feature as the cache is mounted into /cache.


### buildkit(git, image, context, dockerfile, **kwargs)


Build a Docker image using Buildkit.



