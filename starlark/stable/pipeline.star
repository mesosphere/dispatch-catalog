# vi:syntax=python

load("/starlark/stable/k8s", "secret_var", "sanitize")

__doc__ = """
# Pipeline

This module provides methods useful for crafting the basic Dispatch pipeline resources in Starlark.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline@0.0.7", "image_resource")
```

"""

def image_resource(name, url, digest="", pipeline=None):
    """
    Define a new image resource in a pipeline.

    Example usage: `image_resource("my-image", "mesosphere/dispatch:latest")`
    """

    resource(name, type="image", params={
        "url": url,
        "digest": digest
    }, pipeline=pipeline)
    return name

def storage_resource(name, location="", secret="s3-config", pipeline=None):
    """
    Create a new S3-compatible resource.

    If location is not set, it defaults to Dispatch's default MinIO storage.
    If secret is not set, it defaults to Dispatch's default S3 configuration secret.

    Example usage: `storage_resource("my-storage", location="s3://my-bucket/path", secret="my-boto-secret")`
    """

    resource(name, type="storage", params={
        "type": "gcs",
        "location": location,
        "dir": "y"
    }, secrets={
        "BOTO_CONFIG": k8s.corev1.SecretKeySelector(key="boto", localObjectReference=k8s.corev1.LocalObjectReference(name=secret))
    }, pipeline=pipeline)
    return name

def image_reference(name):
    """
    Shorthand for input image reference with digest.

    Returns string "$(resources.inputs.<name>.url)@$(resources.inputs.<name>.digest)".
    """

    return "$(resources.inputs.{}.url)@$(resources.inputs.{}.digest)".format(name, name)

def storage_dir(name):
    """
    Shorthand for input storage root dir.

    Returns string "$(resources.inputs.<name>.path)".
    """

    return "$(resources.inputs.{}.path)".format(name)

def task_step_result(task, step):
    """
    Shorthand for a task step result variable.

    Returns string "$(inputs.tasks.<task>.<step>)".
    """

    return "$(inputs.tasks.{}.{})".format(task, step)
