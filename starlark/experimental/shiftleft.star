# vi:syntax=python

load("github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline@master", "imageResource", "storageResource", "resourceVar")

__doc__ = """
# Shiftleft

Provides methods for running shiftleft scans (https://www.shiftleft.io/scan/) on your CI.

To import, add the following to your Dispatchfile:

```
// TODO
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/shiftleft@master", "sastscan")
```

"""

# TODO : relcoate this to a better location
def sastscan(git, name, image="shiftleft/sast-scan", tag="latest", srcDir=None, **kwargs):
    """
    Runs a shiftleft scan using the provided image on a given directory
    """
    if not srcDir:
        srcDir = "/workspace/{}".format(git)
    outDir = "/workspace/output/{}".format(name)
    task(name, inputs=[git], outputs=[ storageResource(name) ], steps=[
        k8s.corev1.Container(
            name="sast-scan-shiftleft-{}".format(git),
            image="{}:{}".format(image, tag),
            workingDir=srcDir,
            command=[
                "scan",
                "--src={}".format(srcDir),
                "--out_dir={}".format(outDir),
            ],
        )], **kwargs)
    return name
