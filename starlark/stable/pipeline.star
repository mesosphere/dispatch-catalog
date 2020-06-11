# vi:syntax=python

load("/starlark/stable/k8s", "secret_var", "sanitize")

__doc__ = """
# Pipeline

This module provides methods useful for crafting the basic Dispatch pipeline resources in Starlark.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline@0.0.5", "git_resource")
```

"""

def push(**kwargs):
    """
    A sugar function for creating a new push condition.

    Example usage: `action(tasks=["test"], on=push(branches=["master"]))`
    """

    return p.Condition(push=p.PushCondition(**kwargs))

def tag(**kwargs):
    """
    A sugar function for creating a new tag condition.

    Example usage: `action(tasks=["test"], on=tag())`
    """

    return p.Condition(tag=p.TagCondition(**kwargs))

def pull_request(**kwargs):
    """
    A sugar function for creating a new pull request condition.

    Example usage: `action(tasks=["test"], on=pull_request(chatops=["build"]))`
    """

    return p.Condition(pull_request=p.PullRequestCondition(**kwargs))

def cron(**kwargs):
    """
    A sugar function for creating a new cron condition.

    Example usage: `action(tasks=["test"], on=cron(schedule=["build"], revision="release-1.0"))`
    """
    return p.Condition(cron=p.CronCondition(**kwargs))

def pullRequest(**kwargs):
    """
    DEPRECATED: Use pull_request instead.
    """
    return pull_request(**kwargs)

def git_resource(name, url="$(context.git.url)", revision="$(context.git.commit)", pipeline=None):
    """
    Define a new git resource in a pipeline.

    If url is not set, it defaults to the Git URL triggering this build, i.e., "$(context.git.url)".
    If revision is not set, it defaults to the commit SHA triggering this build, i.e., "$(context.git.commit)".

    Example usage: `git_resource("my-git", url="https://github.com/mesosphere/dispatch", revision="dev")`
    """

    resource(name, type="git", params={
        "url": url,
        "revision": revision
    }, pipeline=pipeline)
    return name

def gitResource(name, url="$(context.git.url)", revision="$(context.git.commit)", pipeline=None):
    """
    DEPRECATED: Use git_resource instead.
    """

    return git_resource(name, url=url, revision=revision, pipeline=pipeline)

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

def storage_resource(name, location="s3://artifacts", secret="s3-config", pipeline=None):
    """
    Create a new S3-compatible resource.

    If location is not set, it defaults to Dispatch's default MinIO storage.
    If secret is not set, it defaults to Dispatch's default S3 configuration secret.

    Example usage: `storage_resource("my-storage", location="s3://my-bucket/path", secret="my-boto-secret")`
    """

    resource(name, type="storage", params={
        "type": "gcs",
        "location": "{}/{}".format(location, name),
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

def git_revision(name):
    """
    Shorthand for input git revision.

    Returns string "$(resources.inputs.<name>.revision)"
    """

    return "$(resources.inputs.{}.revision)".format(name)

def git_checkout_dir(name):
    """
    Shorthand for input git checkout directory.

    Returns string "$(resources.inputs.<name>.path)".
    """

    return"$(resources.inputs.{}.path)".format(name)

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
