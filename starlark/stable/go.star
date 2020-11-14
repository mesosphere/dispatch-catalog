# vi:syntax=python

load("/starlark/stable/path", "join")
load("/starlark/stable/pipeline", "image_resource", "storage_resource")
load("/starlark/stable/git", "git_checkout_dir")

__doc__ = """
# Go

Provides methods for building and testing Go modules.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/go@0.0.7", "go")
```
"""

def go_test(task_name, git_name, paths=["./..."], image="golang:1.14", inputs=[], outputs=[], steps=[], **kwargs):
    """
    Run Go tests and generate a coverage report.
    """

    storage_name = storage_resource("storage-{}".format(task_name))

    inputs = inputs + [git_name]
    outputs = outputs + [storage_name]
    steps = steps + [
        step("go-test",
            image=image,
            command=["sh", "-c", """\
set -x
go test -v -coverprofile $(resources.outputs.{storage}.path)/coverage.out {paths}
go tool cover -func $(resources.outputs.{storage}.path)/coverage.out | tee $(resources.outputs.{storage}.path)/coverage.txt
            """.format(
                storage=storage_name,
                paths=" ".join(paths)
            )],
            env=[k8s.corev1.EnvVar(name="GO111MODULE", value="on")],
            workingDir=git_checkout_dir(git_name)
        )
    ]

    task(task_name, inputs=inputs, outputs=outputs, steps=steps, **kwargs)

    return storage_name

def go(task_name, git_name, paths=["./..."], image="golang:1.14", ldflags=None, os=["linux"], arch=["amd64"], inputs=[], outputs=[], steps=[], **kwargs):
    """
    Build a Go binary.
    """

    storage_name = storage_resource("storage-{}".format(task_name))

    inputs = inputs + [git_name]
    outputs = outputs + [storage_name]

    build_args = []
    if ldflags:
        build_args += ["-ldflags", ldflags]

    for goos in os:
        for goarch in arch:
            steps = steps + [
                step("go-build-{}-{}".format(goos, goarch),
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
                    workingDir=git_checkout_dir(git_name)
                )
            ]

    task(task_name, inputs=inputs, outputs=outputs, steps=steps, **kwargs)

    return storage_name

def ko(task_name, git_name, image_repo, path, tag="$(context.build.name)", ldflags=None, working_dir="", inputs=[], outputs=[], steps=[], env=[], **kwargs):
    """
    Build a Docker container for a Go binary using ko.

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

    env = [
        k8s.corev1.EnvVar(name="GO111MODULE", value="on"),
        k8s.corev1.EnvVar(name="KO_DOCKER_REPO", value="-") # This value is arbitrary to pass ko's validation.
    ]

    if ldflags:
        env.append(k8s.corev1.EnvVar(name="GOFLAGS", value="-ldflags={}".format(ldflags)))

    steps = steps + [
        step("build",
            image="gcr.io/tekton-releases/dogfooding/ko:latest",
            command=[
                "ko", "publish",
                "--oci-layout-path=$(resources.outputs.{}.path)".format(image_name),
                "--push=false",
                path
            ],
            env=env,
            workingDir=join(git_checkout_dir(git_name), working_dir),
        ),
        step(
            name="push",
            image="gcr.io/tekton-releases/dogfooding/skopeo:latest",
            command=[
                "skopeo", "copy",
                "oci:$(resources.outputs.{}.path)/".format(image_name),
                "docker://$(resources.outputs.{}.url):{}".format(image_name, tag)
            ],
        )
    ]

    task(task_name, inputs=inputs, outputs=outputs, steps=steps, **kwargs)

    return image_name
