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

def push(**kwargs):
    """
    A sugar function for creating a new push condition.

    Example usage: `action(tasks=["test"], on=push(branches=["master"]))`
    """

    return p.Condition(git=p.GitCondition(push=p.GitPushCondition(**kwargs)))

def tag(**kwargs):
    """
    A sugar function for creating a new tag condition.

    Example usage: `action(tasks=["test"], on=tag())`
    """

    return p.Condition(git=p.GitCondition(tag=p.GitTagCondition(**kwargs)))

def pull_request(**kwargs):
    """
    A sugar function for creating a new pull request condition.

    Example usage: `action(tasks=["test"], on=pull_request(chatops=["build"]))`
    """

    return p.Condition(git=p.GitCondition(pull_request=p.GitPullRequestCondition(**kwargs)))

def cron(**kwargs):
    """
    A sugar function for creating a new cron condition.

    Example usage: `action(name="my-nightly-build", tasks=["test"], on=cron(schedule="@daily", revision="release-1.0"))`
    """
    return p.Condition(cron=p.CronCondition(git=p.GitCronConfig(**kwargs)))

def pullRequest(**kwargs):
    """
    DEPRECATED: Use pull_request instead.
    """
    return pull_request(**kwargs)

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

def imageResource(name, url, digest, pipeline=None):
    """
    DEPRECATED: Use image_resource instead.
    """

    return image_resource(name, url, digest=digest, pipeline=pipeline)

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

def storageResource(name):
    """
    DEPRECATED: Use storage_resource instead.
    """

    return storage_resource(name)

def resourceVar(name, key):
    """
    DEPRECATED: Use dedicated resource variable helpers instead.

    Shorthand for a resource variable, returns a string "$(inputs.resources.<name>.<key>)"
    """

    return "$(inputs.resources.{}.{})".format(name, key)

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

def secretVar(name, key):
    """
    DEPRECATED: Use secret_var in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.
    """

    return secret_var(name, key)

def volume(name, **kwargs):
    """
    DEPRECATED: Use volume source helpers in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.
    """

    return k8s.corev1.Volume(name=name, volumeSource=k8s.corev1.VolumeSource(**kwargs))

def clean(name):
    """
    DEPRECATED: Use sanitize in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.
    """

    return sanitize(name)
