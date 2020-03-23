# vi:syntax=python

__doc__ = """
# Pipeline

This module provides methods useful for crafting the basic Dispatch pipeline resources in Starlark.

Import URL: `github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline`
"""

def push(**kwargs):
    """
    A sugar function for creating a new push condition.

    Example usage: `action(tasks = ["test"], on = push(branches = ["master"]))`
    """
    return p.Condition(push=p.PushCondition(**kwargs))

def tag(**kwargs):
    """
    A sugar function for creating a new tag condition.

    Example usage: `action(tasks = ["test"], on = tag())`
    """
    return p.Condition(tag=p.TagCondition(**kwargs))

def pullRequest(**kwargs):
    """
    A sugar function for creating a new pull request condition.

    Example usage: `action(tasks = ["test"], on = pullRequest(chatops=["build"]))`
    """
    return p.Condition(pull_request=p.PullRequestCondition(**kwargs))

def gitResource(name, url="$(context.git.url)", revision="$(context.git.commit)", pipeline=None):
    """
    Define a new git resource in a pipeline.

    Example usage: `gitResource("git", url="$(context.git.url)", revision="$(context.git.commit)")`
    """
    resource(name, type = "git", params = {
        "url": url,
        "revision": revision,
    }, pipeline=pipeline)
    return name

def imageResource(name, url, digest, pipeline=None):
    """
    Define a new image resource in a pipeline.

    Example usage: `imageResource("my-image", url="mesosphere/dispatch:latest")`
    """
    return resource(name, type = "image", params = {
        "url": url,
        "digest": digest
    }, pipeline=pipeline)

def volume(name, **kwargs):
    """
    Create a new volume given a volume source.
    """
    return k8s.corev1.Volume(name=name, volumeSource=k8s.corev1.VolumeSource(**kwargs))

def resourceVar(name, key):
    """
    Shorthand for a resource variable, returns a string "$(inputs.resources.<name>.<key>)"
    """
    return "$(inputs.resources.{}.{})".format(name, key)

def secretVar(name, key):
    """
    Convenience function for adding an environment variable from a Kubernetes secret.

    Example usage: `k8s.corev1.EnvVar(name="GITHUB_TOKEN", valueFrom=secretVar("scmtoken", "password"))`
    """
    return k8s.corev1.EnvVarSource(secretKeyRef=k8s.corev1.SecretKeySelector(localObjectReference=k8s.corev1.LocalObjectReference(name=name), key=key))

def storageResource(name):
    """
    Create a new S3 resource using the Dispatch default s3 configuration file.
    """
    resource(name, type = "storage", params = {
        "type": "gcs",
        "location": "s3://artifacts",
    }, secrets = {
        "BOTO_CONFIG": k8s.corev1.SecretKeySelector(key = "boto", localObjectReference = k8s.corev1.LocalObjectReference(name = "s3-config"))
    })

    return name

def clean(name):
    """
    Sanitize a name for passing in to Kubernetes / Dispatch.
    """
    return name.replace("/", "-").replace(":", "-").replace(".", "-")
