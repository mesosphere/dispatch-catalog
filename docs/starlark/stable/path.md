
# Path

This module provides utility methods for manipulating slash-separated paths.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/path@0.0.7", "basename")
```


### basename(path)


Returns the base name of `path`. Returns '' if `path` contains trailing slashes.


### dirname(path)


Returns the directory name of `path`. Trailing slashes will be removed unless the directory is equivalent to root.


### splitext(path)


Splits `path` into its root name and file extension. Leading periods on `path` are ignored.


### join(path, paths)

Join two or more path components, inserting '/' as needed.
If any component is an absolute path, all previous path components
will be discarded.


