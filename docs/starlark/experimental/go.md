
# Go

Provides methods for building and testing Go modules.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/go@0.0.7", "go")
```


### ko(task_name, git_name, image_repo, path, tag, ldflags, working_dir, inputs, outputs, steps, env, volumes, **kwargs)


Build a Docker image for a Go binary using ko.

Args:
    `working_dir` optionally can provide a path to a subdirectory within
    the git repository. This can be used if repository has multiple
    go modules and there is a need to build the module that is outside of
    root directory.


### ko_resolve(task_name, git_name, image_root, path, tag, ldflags, working_dir, inputs, outputs, steps, env, volumes, **kwargs)


Build and resolve all Go binary references within the YAML files in the provided path into Docker images using ko.

Args:
    `image_root` is the root URL to publish all images, for example,
    `docker.io/<username>`.

    `working_dir` optionally can provide a path to a subdirectory within
    the git repository. This can be used if repository has multiple
    go modules and there is a need to build the module that is outside of
    root directory.


### go_test(task_name, git_name, paths, image, volumeMounts, inputs, outputs, steps, env, volumes, **kwargs)


Run Go tests and generate a coverage report.


### go(task_name, git_name, paths, image, ldflags, os, arch, inputs, outputs, steps, volumes, **kwargs)


Build Go binaries.



