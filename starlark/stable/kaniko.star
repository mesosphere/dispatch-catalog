# vi:syntax=python

load("/starlark/stable/pipeline", "sanitize", "image_resource")

__doc__ = """
# Kaniko

Provides methods for building Docker containers using Kaniko.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/kaniko@0.0.4", "kaniko")
```

"""

def kaniko(task_name, git_name, image_repo, context="", dockerfile="Dockerfile", tag="$(context.build.name)", **kwargs):
    """
    Build a Docker image using Kaniko.
    """
    image_with_tag = "{}:{}".format(image_repo, tag)

    image_name = image_resource("image-{}".format(sanitize(image_repo)), url=image_with_tag)

    build_args = []
    for k, v in kwargs.get("buildArgs", {}).items():
        build_args.append("--build-arg={}={}".format(k, v))

    task(task_name, inputs = [git_name]+kwargs.get("inputs", []), outputs = [image_name], steps=[
        v1.Container(
            name = "docker-build",
            image = "chhsiao/kaniko-executor",
            args= build_args+[
                "--destination={}".format(image_with_tag),
                "--context=/workspace/{}/{}".format(git_name, context),
                "--oci-layout-path=/workspace/output/{}".format(image_name),
                "--dockerfile=/workspace/{}/{}".format(git_name, dockerfile)
            ]
        )]
    )

    return image_name
