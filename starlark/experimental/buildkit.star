# vi:syntax=python

load("/starlark/stable/pipeline", "image_resource", "git_checkout_dir")

__doc__ = """
# Buildkit

Provides methods for interacting with a Buildkit instance.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/buildkit@0.0.5", "buildkit")
```

"""

def buildkit_container(name, image, workingDir, command, output_paths=[], **kwargs):
    """
    buildkit_container returns a Kubernetes corev1.Container that runs inside of buildkit.
    The container can take advantage of buildkit's cache mount feature as the cache is mounted into /cache.
    """

    env = ""
    for env_var in kwargs.get("env", []):
        env += "ENV {} {}\n".format(env_var.name, env_var.value)

    add_outputs = ""
    copy_outputs = ""
    for output in output_paths:
        add_outputs += "ADD {output} {output}\n".format(output=output)
        copy_outputs += "COPY --from=0 {output} {output}\n".format(output=output)

    dockerfile = """\
# syntax = docker/dockerfile:experimental
FROM {image}
WORKDIR {working_dir}
ENV GOCACHE /cache/go-cache
ENV GOPATH /cache/go
ENV DOCKER_CONFIG /tekton/home/.docker
{env}
ADD /tekton/home/.docker /tekton/home/.docker
{add_outputs}
ADD {working_dir} {working_dir}
RUN --mount=type=cache,target=/cache {command}

FROM scratch
{copy_outputs}
COPY --from=0 {working_dir} {working_dir}
    """.format(
        image=image,
        working_dir=workingDir,
        env=env,
        add_outputs=add_outputs,
        command=command,
        copy_outputs=copy_outputs
    )

    return k8s.corev1.Container(
        name=name,
        image="moby/buildkit:v0.6.2",
        workingDir=workingDir,
        command=["sh", "-c", """\
cat > /tmp/Dockerfile.buildkit <<EOF
{}
EOF
buildctl --debug --addr=tcp://buildkitd.buildkit:1234 build \
    --progress=plain \
    --frontend=dockerfile.v0 \
    --local context=/ \
    --local dockerfile=/tmp \
    --output type=local,dest=/ \
    --opt filename=Dockerfile.buildkit
        """.format(dockerfile)],
        **kwargs
    )

def buildkit(task_name, git_name, image_repo, tag="$(context.build.name)", context=".", dockerfile="Dockerfile", build_args={}, build_env={}, env=[], inputs=[], outputs=[], steps=[], volumes=[], **kwargs):
    """
    Build a Docker image using Buildkit.
    """

    image_name = image_resource(
        "image-{}".format(task_name),
        url=image_repo
    )

    inputs = inputs + [git_name]
    outputs = outputs + [image_name]
    volumes = volumes + [k8s.corev1.Volume(name = "buildkit-wd")]

    command = [
        "buildctl", "--debug", "--addr=tcp://buildkitd.buildkit:1234", "build",
        "--progress=plain",
        "--frontend=dockerfile.v0",
        "--local", "context={}".format(context),
        "--local", "dockerfile=.",
        "--output", "type=docker,dest=/wd/image.tar",
        "--opt", "filename={}".format(dockerfile)
    ]

    for k, v in build_args.items():
      command += ["--opt", "build-arg:{}={}".format(k, v)]

    for k, v in build_env.items():
      command += ["--opt", "build-env:{}={}".format(k, v)]

    steps = steps + [
        k8s.corev1.Container(
            name="build",
            image="moby/buildkit:v0.6.2",
            workingDir=git_checkout_dir(git_name),
            command=command,
            volumeMounts=[k8s.corev1.VolumeMount(name="buildkit-wd", mountPath="/wd")],
            env=env
        ),
        k8s.corev1.Container(
            name="extract-and-push",
            image="gcr.io/tekton-releases/dogfooding/skopeo:latest",
            command=["sh", "-c", """\
tar -xf /wd/image.tar -C $(resources.outputs.{image}.path)/
skopeo copy oci:$(resources.outputs.{image}.path)/ docker://$(resources.outputs.{image}.url):{tag}
            """.format(
                image=image_name,
                tag=tag
            )],
            volumeMounts=[k8s.corev1.VolumeMount(name="buildkit-wd", mountPath="/wd")],
            env=env
        )
    ]

    task(task_name, inputs=inputs, env=env, outputs=outputs, steps=steps, volumes=volumes, **kwargs)

    return image_name
