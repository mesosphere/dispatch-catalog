
# Go

Provides methods for building and testing Go modules.

Import URL: `github.com/mesosphere/dispatch-catalog/starlark/stable/go`

### go_test(git, name, paths, **kwargs)


Run Go tests and generate a coverage report.


### go(git, name, ldflags, os, **kwargs)


Build a Go binary.


### ko(git, name, ko_docker_repo, ldflags, ko_image, inputs, *args, **kwargs)


Build a Docker container for a Go binary using ko.



