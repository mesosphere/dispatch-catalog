# vi:syntax=python

load("/starlark/stable/pipeline", "git_checkout_dir", "storage_resource")

__doc__ = """
# Shiftleft

Provides methods for running [shiftleft scans](https://www.shiftleft.io/scan/) on your CI.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/shiftleft@master", "sast_scan")
```

"""

def sast_scan(task_name, git_name, image_and_tag="shiftleft/sast-scan:latest", src=None, extra_scan_options=None, **kwargs):
    """
    Runs a shiftleft scan using the provided image on a given directory.
    
    #### Parameters
    - *task_name* : name of the task to be created
    - *git_name* : input git resource name
    - *image_and_tag* : image (with tag) of the shiftleft scan
    - *src* : Optional string to override the `src` directory to run the scan. Defaults to given git resource directory.
    - *extra_scan_options* : Optional dict containing flag names and values to be passed to scan command
    """
    if not src:
        src = git_checkout_dir(git_name)
    output_name = storage_resource("storage-{}".format(task_name))

    extra_command_flags = []
    if extra_scan_options:
        for key in extra_scan_options.iterkeys():
            extra_command_flags.append("--{}={}".format(key, extra_scan_options[key]))

    task(task_name, inputs=[git_name], outputs=[output_name], steps=[
        k8s.corev1.Container(
            name="sast-scan-shiftleft-{}".format(git_name),
            image=image_and_tag,
            command=[
                "scan",
                "--src={}".format(src),
                "--out_dir={}".format("$(resources.outputs.{}.path)".format(output_name)),
            ] + extra_command_flags,
        )], **kwargs)
    return output_name
