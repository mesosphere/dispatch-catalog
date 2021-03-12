# vi:syntax=python

load("/starlark/stable/path", "basename", "splitext", "join")
load("/starlark/stable/pipeline", "image_resource", "storage_resource")
load("/starlark/stable/git", "git_checkout_dir")
load("/starlark/experimental/buildkit", "buildkit_container", "buildkit_volumes")

__doc__ = """
# Go

Provides methods for building and testing Go modules.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/go@0.0.7", "go")
```

"""

def go_test(task_name, git_name, paths=["./..."], image="golang:1.14", volumeMounts=[], inputs=[], outputs=[], steps=[], env=[], volumes=[], **kwargs):
    """
    Run Go tests and generate a coverage report.
    """

    storage_name = storage_resource("storage-{}".format(task_name))

    inputs = inputs + [git_name]
    outputs = outputs + [storage_name]
    volumes = volumes + buildkit_volumes()

    env = env + [k8s.corev1.EnvVar(name="GO111MODULE", value="on")]
    input_paths = [vm.mountPath for vm in volumeMounts]
    output_paths = ["$(resources.outputs.{}.path)".format(storage_name)]
    steps = steps + [
        buildkit_container(
            name="go-test",
            image=image,
            workingDir=git_checkout_dir(git_name),
            command=["sh", "-c", """\
set -xe
go test -v -coverprofile $(resources.outputs.{storage}.path)/coverage.out {paths}
go tool cover -func $(resources.outputs.{storage}.path)/coverage.out | tee $(resources.outputs.{storage}.path)/coverage.txt
            """.format(
                storage=storage_name,
                paths=" ".join(paths)
            )],
            env=env,
            input_paths=input_paths,
            output_paths=output_paths,
            volumeMounts=volumeMounts
        )
    ]

    task(task_name, inputs=inputs, outputs=outputs, steps=steps, volumes=volumes, **kwargs)

    return storage_name

def go(task_name, git_name, paths=["./..."], image="golang:1.14", ldflags=None, os=["linux"], arch=["amd64"], inputs=[], outputs=[], steps=[], volumes=[], **kwargs):
    """
    Build Go binaries.
    """

    storage_name = storage_resource("storage-{}".format(task_name))

    inputs = inputs + [git_name]
    outputs = outputs + [storage_name]
    volumes = volumes + buildkit_volumes()

    build_args = []
    if ldflags:
        build_args += ["-ldflags", ldflags]

    for goos in os:
        for goarch in arch:
            steps = steps + [
                buildkit_container(
                    name="go-build-{}-{}".format(goos, goarch),
                    image=image,
                    command=["sh", "-c", """\
mkdir -p $(resources.outputs.{storage}.path)/{os}_{arch}/
go build -o $(resources.outputs.{storage}.path)/{os}_{arch}/ {build_args} {paths}
                    """.format(
                        storage=storage_name,
                        os=goos,
                        arch=goarch,
                        build_args=" ".join(build_args),
                        paths=" ".join(paths)
                    )],
                    env=[
                        k8s.corev1.EnvVar(name="GO111MODULE", value="on"),
                        k8s.corev1.EnvVar(name="GOOS", value=goos),
                        k8s.corev1.EnvVar(name="GOARCH", value=goarch)
                    ],
                    workingDir=git_checkout_dir(git_name),
                    output_paths=["$(resources.outputs.{}.path)".format(storage_name)]
                )
            ]

    task(task_name, inputs=inputs, outputs=outputs, steps=steps, volumes=volumes, **kwargs)

    return storage_name

def ko(task_name, git_name, image_repo, path, tag="$(context.build.name)", ldflags=None, working_dir="", inputs=[], outputs=[], steps=[], env=[], volumes=[], **kwargs):
    """
    Build a Docker image for a Go binary using ko.

    Args:
        `working_dir` optionally can provide a path to a subdirectory within
        the git repository. This can be used if repository has multiple
        go modules and there is a need to build the module that is outside of
        root directory.
    """

    image_name = image_resource(
        "image-{}".format(task_name),
        url=image_repo
    )

    inputs = inputs + [git_name]
    outputs = outputs + [image_name]
    volumes = volumes + buildkit_volumes()

    env = env + [
        k8s.corev1.EnvVar(name="GO111MODULE", value="on"),
        k8s.corev1.EnvVar(name="KO_DOCKER_REPO", value="-") # This value is arbitrary to pass ko's validation.
    ]

    if ldflags:
        env.append(k8s.corev1.EnvVar(name="GOFLAGS", value="-ldflags={}".format(ldflags)))

    steps = steps + [buildkit_container(
        name="build",
        image="gcr.io/tekton-releases/dogfooding/ko:latest",
        command=[
            "ko", "publish",
            "--oci-layout-path=$(resources.outputs.{}.path)".format(image_name),
            "--push=false",
            path
        ],
        env=env,
        workingDir=join(git_checkout_dir(git_name), working_dir),
        output_paths=["$(resources.outputs.{}.path)".format(image_name)]
    ), k8s.corev1.Container(
        name="push",
        image="gcr.io/tekton-releases/dogfooding/skopeo:latest",
        command=[
            "skopeo", "copy",
            "oci:$(resources.outputs.{}.path)/".format(image_name),
            "docker://$(resources.outputs.{}.url):{}".format(image_name, tag)
        ],
    )]

    task(task_name, inputs=inputs, outputs=outputs, steps=steps, volumes=volumes, **kwargs)

    return image_name

def ko_resolve(task_name, git_name, image_root, path, tag="", ldflags=None, working_dir="", inputs=[], outputs=[], steps=[], env=[], volumes=[], **kwargs):
    """
    Build and resolve all Go binary references within the YAML files in the provided path into Docker images using ko.

    Args:
        `image_root` is the root URL to publish all images, for example,
        `docker.io/<username>`.

        `working_dir` optionally can provide a path to a subdirectory within
        the git repository. This can be used if repository has multiple
        go modules and there is a need to build the module that is outside of
        root directory.
    """

    storage_name = storage_resource("storage-{}".format(task_name))

    inputs = inputs + [git_name]
    outputs = outputs + [storage_name]
    volumes = volumes + buildkit_volumes()

    env = env + [
        k8s.corev1.EnvVar(name="GO111MODULE", value="on"),
        k8s.corev1.EnvVar(name="KO_DOCKER_REPO", value=image_root),
        k8s.corev1.EnvVar(name="KO_DOCKER_TAG", value=tag)
    ]

    if ldflags:
        env.append(k8s.corev1.EnvVar(name="GOFLAG", value="-ldflags={}".format(ldflags)))

    steps = steps + [buildkit_container(
        name="resolve",
        image="gcr.io/tekton-releases/dogfooding/ko:latest",
        command=["sh", "-c", """
            ko resolve --base-import-paths --filename={} --tags=${{KO_DOCKER_TAG:-latest}} | \
                tee $(resources.outputs.{}.path)/{}.yaml
        """.format(path, storage_name, splitext(basename(path.rstrip("/")))[0])],
        env=env,
        workingDir=join(git_checkout_dir(git_name), working_dir),
        output_paths=["$(resources.outputs.{}.path)".format(storage_name)]
    )]

    task(task_name, inputs=inputs, outputs=outputs, steps=steps, volumes=volumes, **kwargs)

    return storage_name
