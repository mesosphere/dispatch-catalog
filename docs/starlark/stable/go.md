
# Go

Provides methods for building and testing Go modules.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/go@0.0.5", "go")
```

### go(task_name, git_name, paths, image, ldflags, os, arch, inputs, outputs, steps, **kwargs)


Build a Go binary.


### ko(task_name, git_name, image_repo, path, tag, ldflags, working_dir, inputs, outputs, steps, env, **kwargs)

Build a Docker container for a Go binary using ko.


### go_test(task_name, git_name, paths, image, inputs, outputs, steps, **kwargs)


Run Go tests and generate a coverage report.



