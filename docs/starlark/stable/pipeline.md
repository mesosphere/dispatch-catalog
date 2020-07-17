
# Pipeline

This module provides methods useful for crafting the basic Dispatch pipeline resources in Starlark.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline@0.0.5", "git_resource")
```


### pull_request(**kwargs)


A sugar function for creating a new pull request condition.

Example usage: `action(tasks=["test"], on=pull_request(chatops=["build"]))`


### image_resource(name, url, digest, pipeline)


Define a new image resource in a pipeline.

Example usage: `image_resource("my-image", "mesosphere/dispatch:latest")`


### git_revision(name)


Shorthand for input git revision.

Returns string "$(resources.inputs.<name>.revision)"


### git_checkout_dir(name)


Shorthand for input git checkout directory.

Returns string "$(resources.inputs.<name>.path)".


### image_reference(name)


Shorthand for input image reference with digest.

Returns string "$(resources.inputs.<name>.url)@$(resources.inputs.<name>.digest)".


### secretVar(name, key)


DEPRECATED: Use secret_var in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.


### push(**kwargs)


A sugar function for creating a new push condition.

Example usage: `action(tasks=["test"], on=push(branches=["master"]))`


### git_resource(name, url, revision, pipeline)


Define a new git resource in a pipeline.

If url is not set, it defaults to the Git URL triggering this build, i.e., "$(context.git.url)".
If revision is not set, it defaults to the commit SHA triggering this build, i.e., "$(context.git.commit)".

Example usage: `git_resource("my-git", url="https://github.com/mesosphere/dispatch", revision="dev")`


### gitResource(name, url, revision, pipeline)


DEPRECATED: Use git_resource instead.


### volume(name, **kwargs)


DEPRECATED: Use volume source helpers in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.


### clean(name)


DEPRECATED: Use sanitize in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.


### storage_resource(name, location, secret, pipeline)


Create a new S3-compatible resource.

If location is not set, it defaults to Dispatch's default MinIO storage.
If secret is not set, it defaults to Dispatch's default S3 configuration secret.

Example usage: `storage_resource("my-storage", location="s3://my-bucket/path", secret="my-boto-secret")`


### storageResource(name)


DEPRECATED: Use storage_resource instead.


### resourceVar(name, key)


DEPRECATED: Use dedicated resource variable helpers instead.

Shorthand for a resource variable, returns a string "$(inputs.resources.<name>.<key>)"


### generate_version(git, name)


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


### tag(**kwargs)


A sugar function for creating a new tag condition.

Example usage: `action(tasks=["test"], on=tag())`


### pullRequest(**kwargs)


DEPRECATED: Use pull_request instead.


### imageResource(name, url, digest, pipeline)


DEPRECATED: Use image_resource instead.


### storage_dir(name)


Shorthand for input storage root dir.

Returns string "$(resources.inputs.<name>.path)".


### task_step_result(task, step)


Shorthand for a task step result variable.

Returns string "$(inputs.tasks.<task>.<step>)".



