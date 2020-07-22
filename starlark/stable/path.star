# vi:syntax=python

__doc__ = """
# Path

This module provides utility methods for manipulating slash-separated paths.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/path@0.0.7", "basename")
```

"""

def basename(path):
    """
    Returns the base name of `path`. Returns '' if `path` contains trailing slashes.
    """

    return path.rpartition("/")[2]

def join(path, *paths):
    """Join two or more path components, inserting '/' as needed.
    If any component is an absolute path, all previous path components
    will be discarded."""

    for p in paths:
        if p.startswith("/"):
            path = p
        elif p != "":
            path += ("" if path == "" or path.endswith("/") else "/") + p
    return path
