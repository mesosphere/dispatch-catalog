# vi:syntax=python

load("/starlark/stable/pipeline", "task_step_result")

__doc__ = """
# Git

This module provides methods useful for working with git repositories.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/git@0.0.6", "generate_version")
```

"""

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

def generate_version(git, name):
    """
    Generates a version number from the git repository. It uses the output of `git describe --tags`
    as the version number. If the commit is tagged, the tag will be used. If the commit is not tagged,
    it will use the most recent tag in the tree concatenated with the commit index and the short commit
    id (e.g., "1.2.0-154-geb24b488").

    Arguments:
    * `git`: the git repository resource to use for calculating the version.
    * `name`: the name of the task to create.

    Returns the task result variable name that can be used to access the version. A task using the
    version number must list the version task name (the value specified in the name argument) in the task's inputs
    and then the variable can be accessed from within the task.

    Example usage:

        git          = git_resource("git")
        version_task = "generate-version"
        version      = generate_version(git, version_task)

        task("print-version", inputs=[version_task], steps=[
            k8s.corev1.Container(
                name="print-version",
                image="alpine",
                command=[
                    "/bin/ash", "-c", "echo {}".format(version)
                ]
            )
        ])
    """
    task(name, inputs=[git], steps=[
        k8s.corev1.Container(
            name="version",
            image="alpine/git",
            workingDir=git_checkout_dir(git),
            command=[
                "/bin/ash", "-c", "git fetch --unshallow --tags origin && git describe --tags"
            ]
        )
    ])
    return task_step_result(name, "version")
