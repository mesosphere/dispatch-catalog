# vi:syntax=python

load("/starlark/stable/pipeline", "image_resource")
load("/starlark/stable/git", "git_checkout_dir")

__doc__ = """
# Kaniko

Provides methods for building Docker containers using Kaniko.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/kaniko@0.0.7", "kaniko")
```

"""

def kaniko(task_name, git_name, image_repo, tag="$(context.build.name)", context=".", dockerfile="Dockerfile", build_args={}, inputs=[], outputs=[], steps=[], **kwargs):
    """
    Build a Docker image using Kaniko.
    """

    image_name = image_resource(
        "image-{}".format(task_name),
        url=image_repo
    )

    inputs = inputs + [git_name]
    outputs = outputs + [image_name]

    args = [
        "--destination=$(resources.outputs.{}.url):{}".format(image_name, tag),
        "--context={}".format(context),
        "--oci-layout-path=$(resources.outputs.{}.path)".format(image_name),
        "--dockerfile={}".format(dockerfile)
    ]

    for k, v in build_args.items():
        args.append("--build-arg={}={}".format(k, v))

    steps = steps + [
        k8s.corev1.Container(
            name="build",
            image="gcr.io/kaniko-project/executor:latest",
            args=args,
            workingDir=git_checkout_dir(git_name)
        )
    ]

    task(task_name, inputs=inputs, outputs=outputs, steps=steps, **kwargs)

    return image_name
