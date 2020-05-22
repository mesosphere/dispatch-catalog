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

buildx_image = "jbarrickmesosphere/buildx@sha256:6c63494ccd7a783b4a0d197f9dd91845543c5e04c1c73d94fef9dfdbbf962b3c"

def buildkit_install(replicas=3, cluster_name="buildkit"):
    return k8s.corev1.Container(
        name = "install-buildkit",
        image = buildx_image,
        command = [
            "docker", "buildx", "create", "--driver=kubernetes",
            "--driver-opt=replicas={}".format(replicas), "--use", "--name={}".format(cluster_name)
        ]
    )

def buildkit_container(name, image, workingDir, command, output_paths=[], replicas=3, cluster_name="buildkit", **kwargs):
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
        image=buildx_image,
        workingDir=workingDir,
        command=["sh", "-c", """\
cat > /tmp/Dockerfile.buildkit <<EOF
{dockerfile}
EOF

docker buildx create --driver=kubernetes --driver-opt=replicas={replicas} --use --name={cluster_name}
docker buildx build -f Dockerfile.buildkit / -o type=local,dest=/
        """.format(dockerfile=dockerfile, replicas=replicas, cluster_name=cluster_name)],
        **kwargs
    )

def buildkit(task_name, git_name, image_repo, tag="$(context.build.name)", context=".", dockerfile="Dockerfile", replicas=3, cluster_name="buildkit", build_args={}, inputs=[], outputs=[], steps=[], volumes=[], **kwargs):
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

    for k, v in build_args.items():
      command += ["--opt", "build-arg:{}={}".format(k, v)]

    steps = steps + [
        k8s.corev1.Container(
            name = "install-buildkit",
            image = buildx_image,
            command = [
                "docker", "buildx", "create", "--driver=kubernetes",
                "--driver-opt=replicas={}".format(replicas), "--use", "--name={}".format(cluster_name)
            ]
        ),
        k8s.corev1.Container(
            name = "build-image",
            image = buildx_image,
            workingDir = git_checkout_dir(git_name),
            command = [
                "docker", "buildx", "build", "-f", dockerfile, context, "-o", "type=docker,dest=/wd/image.tar"
            ],
            volumeMounts = [k8s.corev1.VolumeMount(name = "buildkit-wd", mountPath = "/wd")]
        ),
        k8s.corev1.Container(
            name = "extract-and-push",
            image = "gcr.io/tekton-releases/dogfooding/skopeo:latest",
            command = ["sh", "-c", """
tar -xf /wd/image.tar -C $(resources.outputs.{name}.path)/
skopeo copy oci:$(resources.outputs.{name}.path)/ docker://$(resources.outputs.{name}.url)
            """.format(name = image_name)],
            volumeMounts = [k8s.corev1.VolumeMount(name = "buildkit-wd", mountPath = "/wd")]
        )
    ]

    task(task_name, inputs=inputs, outputs=outputs, steps=steps, volumes=volumes, **kwargs)

    return image_name
