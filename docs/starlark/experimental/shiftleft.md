
# Shiftleft

Provides methods for running [shiftleft scans](https://www.shiftleft.io/scan/) on your CI.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/shiftleft@master", "sast_scan")
```


### sast_scan(task_name, git_name, image, src, extra_scan_options, **kwargs)


Runs a shiftleft scan using the provided image on a given directory.

#### Parameters
- *task_name* : name of the task to be created
- *git_name* : input git resource name
- *image* : image (with tag) of the shiftleft scan
- *src* : Optional string to override the `src` directory to run the scan. Defaults to given git resource directory.
- *extra_scan_options* : Optional array containing flag names (and values) to be passed to scan command



