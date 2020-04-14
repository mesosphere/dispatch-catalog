
# Go

Provides methods for building and testing Go modules.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/go@0.0.4", "ko")
```


### go(git, name, ldflags, os, image, inputs, **kwargs)


Build a Go binary.


### ko(git, image_name, name, ldflags, ko_image, inputs, tag, *args, **kwargs)


Build a Docker container for a Go binary using ko.


### go_test(git, name, paths, image, inputs, **kwargs)


Run Go tests and generate a coverage report.



