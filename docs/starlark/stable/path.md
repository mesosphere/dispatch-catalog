
# Path

This module provides utility methods for manipulating slash-separated paths.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/path@0.0.5", "basename")
```


### basename(path)


Returns the base name of `path`. Returns '' if `path` contains trailing slashes.



