# vi:syntax=python

load("github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline@master", "storageResource")

__doc__ = """
# Shiftleft

Provides methods for running shiftleft scans (https://www.shiftleft.io/scan/) on your CI.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/shiftleft@master", "sastscan")
```

"""

def sastscan(git, task_name, imageAndTag="shiftleft/sast-scan:latest", srcDir=None, **kwargs):
    """
    Runs a shiftleft scan using the provided image on a given directory.
    
    #### Parameters
    *git* : input git resource
    *task_name* : name of the task to be created
    *imageAndTag* : image (with tag) of the shiftleft scan
    *srcDir* : Can optionally provide a `srcDir` arg. Defaults to given git resource directory.
    """
    if not srcDir:
        srcDir = "/workspace/{}".format(git)
    outDir = "/workspace/output/{}".format(task_name)
    task(task_name, inputs=[git], outputs=[storageResource(task_name)], steps=[
        k8s.corev1.Container(
            name="sast-scan-shiftleft-{}".format(git),
            image=imageAndTag,
            workingDir=srcDir,
            command=[
                "scan",
                "--src={}".format(srcDir),
                "--out_dir={}".format(outDir),
            ],
        )], **kwargs)
    return name
