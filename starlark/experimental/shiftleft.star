# vi:syntax=python

load("/starlark/stable/pipeline", "storage_resource")

__doc__ = """
# Shiftleft

Provides methods for running [shiftleft scans](https://www.shiftleft.io/scan/) on your CI.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/shiftleft@master", "sast_scan")
```

"""

def sast_scan(git, task_name, image_and_tag="shiftleft/sast-scan:latest", src=None, extra_scan_options=None, **kwargs):
    """
    Runs a shiftleft scan using the provided image on a given directory.
    
    #### Parameters
    - *git* : input git resource
    - *task_name* : name of the task to be created
    - *image_and_tag* : image (with tag) of the shiftleft scan
    - *src* : Optional string to override the `src` directory to run the scan. Defaults to given git resource directory.
    - *extra_scan_options* : Optional dict containing flag names and values to be passed to scan command
    """
    if not src:
        src = "/workspace/{}".format(git)
    out_dir = "/workspace/output/{}".format(task_name)

    extra_command_flags = []
    if extra_scan_options:
        for key in extra_scan_options.iterkeys():
            extra_command_flags.append("--{}={}".format(key, extra_scan_options[key]))

    task(task_name, inputs=[git], outputs=[storage_resource(task_name)], steps=[
        k8s.corev1.Container(
            name="sast-scan-shiftleft-{}".format(git),
            image=image_and_tag,
            workingDir=src,
            command=[
                "scan",
                "--src={}".format(src),
                "--out_dir={}".format(out_dir),
            ] + extra_command_flags,
        )], **kwargs)
    return task_name
