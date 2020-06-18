
# Pipeline

This module provides methods useful for crafting the basic Dispatch pipeline resources in Starlark.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline@0.0.5", "git_resource")
```


### pull_request(**kwargs)


A sugar function for creating a new pull request condition.

Example usage: `action(tasks=["test"], on=pull_request(chatops=["build"]))`


### gitResource(name, url, revision, pipeline)


DEPRECATED: Use git_resource instead.


### storageResource(name)


DEPRECATED: Use storage_resource instead.


### clean(name)


DEPRECATED: Use sanitize in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.


### resourceVar(name, key)


DEPRECATED: Use dedicated resource variable helpers instead.

Shorthand for a resource variable, returns a string "$(inputs.resources.<name>.<key>)"


### task_step_result(task, step)


Shorthand for a task step result variable.

Returns string "$(inputs.tasks.<task>.<step>)".


### imageResource(name, url, digest, pipeline)


DEPRECATED: Use image_resource instead.


### pullRequest(**kwargs)


DEPRECATED: Use pull_request instead.


### git_resource(name, url, revision, pipeline)


Define a new git resource in a pipeline.

If url is not set, it defaults to the Git URL triggering this build, i.e., "$(context.git.url)".
If revision is not set, it defaults to the commit SHA triggering this build, i.e., "$(context.git.commit)".

Example usage: `git_resource("my-git", url="https://github.com/mesosphere/dispatch", revision="dev")`


### secretVar(name, key)


DEPRECATED: Use secret_var in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.


### volume(name, **kwargs)


DEPRECATED: Use volume source helpers in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.


### tag(**kwargs)


A sugar function for creating a new tag condition.

Example usage: `action(tasks=["test"], on=tag())`


### image_resource(name, url, digest, pipeline)


Define a new image resource in a pipeline.

Example usage: `image_resource("my-image", "mesosphere/dispatch:latest")`


### storage_resource(name, location, secret, pipeline)


Create a new S3-compatible resource.

If location is not set, it defaults to Dispatch's default MinIO storage.
If secret is not set, it defaults to Dispatch's default S3 configuration secret.

Example usage: `storage_resource("my-storage", location="s3://my-bucket/path", secret="my-boto-secret")`


### git_revision(name)


Shorthand for input git revision.

Returns string "$(resources.inputs.<name>.revision)"


### git_checkout_dir(name)


Shorthand for input git checkout directory.

Returns string "$(resources.inputs.<name>.path)".


### image_reference(name)


Shorthand for input image reference with digest.

Returns string "$(resources.inputs.<name>.url)@$(resources.inputs.<name>.digest)".


### storage_dir(name)


Shorthand for input storage root dir.

Returns string "$(resources.inputs.<name>.path)".


### push(**kwargs)


A sugar function for creating a new push condition.

Example usage: `action(tasks=["test"], on=push(branches=["master"]))`



