
# Pipeline

This module provides methods useful for crafting the basic Dispatch pipeline resources in Starlark.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline@0.0.7", "image_resource")
```


### storage_dir(name)


Shorthand for input storage root dir.

Returns string "$(resources.inputs.<name>.path)".


### volume(name, **kwargs)


DEPRECATED: Use volume source helpers in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.


### image_resource(name, url, digest, pipeline)


Define a new image resource in a pipeline.

Example usage: `image_resource("my-image", "mesosphere/dispatch:latest")`


### task_step_result(task, step)


Shorthand for a task step result variable.

Returns string "$(inputs.tasks.<task>.<step>)".


### secretVar(name, key)


DEPRECATED: Use secret_var in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.


### clean(name)


DEPRECATED: Use sanitize in github.com/mesosphere/dispatch-catalog/starlark/stable/k8s instead.


### push(**kwargs)


A sugar function for creating a new push condition.

Example usage: `action(tasks=["test"], on=push(branches=["master"]))`


### pull_request(**kwargs)


A sugar function for creating a new pull request condition.

Example usage: `action(tasks=["test"], on=pull_request(chatops=["build"]))`


### cron(**kwargs)


A sugar function for creating a new cron condition.

Example usage: `action(name="my-nightly-build", tasks=["test"], on=cron(schedule="@daily", revision="release-1.0"))`


### storage_resource(name, location, secret, pipeline)


Create a new S3-compatible resource.

If location is not set, it defaults to Dispatch's default MinIO storage.
If secret is not set, it defaults to Dispatch's default S3 configuration secret.

Example usage: `storage_resource("my-storage", location="s3://my-bucket/path", secret="my-boto-secret")`


### resourceVar(name, key)


DEPRECATED: Use dedicated resource variable helpers instead.

Shorthand for a resource variable, returns a string "$(inputs.resources.<name>.<key>)"


### image_reference(name)


Shorthand for input image reference with digest.

Returns string "$(resources.inputs.<name>.url)@$(resources.inputs.<name>.digest)".


### tag(**kwargs)


A sugar function for creating a new tag condition.

Example usage: `action(tasks=["test"], on=tag())`


### pullRequest(**kwargs)


DEPRECATED: Use pull_request instead.


### imageResource(name, url, digest, pipeline)


DEPRECATED: Use image_resource instead.


### storageResource(name)


DEPRECATED: Use storage_resource instead.



