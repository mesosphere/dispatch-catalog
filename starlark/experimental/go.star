# vi:syntax=python

load("/starlark/stable/pipeline", "git_checkout_dir", "image_resource", "storage_resource")
load("/starlark/stable/path", "basename")
load("/starlark/experimental/buildkit", "buildkit_container")

__doc__ = """
# Go

Provides methods for building and testing Go modules.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/go@0.0.6", "ko")
```

"""

def go_test(task_name, git_name, paths=[], image="golang:1.14", **kwargs):
    """
    Run Go tests and generate a coverage report.
    """
    # TODO(chhsiao): Because the location is deterministic, artifacts will be overwritten by
    # different runs. We should introduce a mechanism to avoid this.
    storage_name = storage_resource("storage-" + task_name, location = "s3://artifacts/{}/".format(task_name))

    kwargs.setdefault("inputs", []).append(git_name)
    kwargs.setdefault("outputs", []).append(storage_name)
    kwargs.setdefault("steps", []).append(
        buildkit_container(
            name = "go-test",
            image = image,
            command = ["sh", "-c", """
go test -v -coverprofile $(resources.outputs.{storage}.path)/coverage.out {paths}
go tool cover -func $(resources.outputs.{storage}.path)/coverage.out | tee $(resources.outputs.{storage}.path)/coverage.txt
diff -uN --label old/coverage.txt --label new/coverage.txt coverage.txt $(resources.outputs.{storage}.path)/coverage.txt
            """.format(storage = storage_name, paths = " ".join(paths))],
            env = [
                k8s.corev1.EnvVar(name = "GO111MODULE", value = "on")
            ],
            workingDir = git_checkout_dir(git_name)
        )
    )

    task(task_name, **kwargs)

    return storage_name

def go(task_name, git_name, path, image="golang:1.14", ldflags=None, os=["linux"], arch=["amd64"], **kwargs):
    """
    Build Go binaries.
    """
    # TODO(chhsiao): Because the location is deterministic, artifacts will be overwritten by
    # different runs. We should introduce a mechanism to avoid this.
    storage_name = storage_resource("storage-" + task_name, location = "s3://artifacts/{}/".format(task_name))

    command = ["go", "build"]

    if ldflags:
        command += ["-ldflags", ldflags]

    steps = []
    for goos in os:
        for goarch in arch:
            steps.append(buildkit_container(
                name = "go-build-{}_{}".format(goos, goarch),
                image = image,
                command = command + ["-o", "$(resources.outputs.{}.path)/{}_{}/{}".format(storage_name, goos, goarch, basename(path)), path],
                env = [
                    k8s.corev1.EnvVar(name = "GO111MODULE", value = "on"),
                    k8s.corev1.EnvVar(name = "GOOS", value = goos),
                    k8s.corev1.EnvVar(name = "GOARCH", value = goarch)
                ],
                workingDir = git_checkout_dir(git_name)
            ))

    kwargs.setdefault("inputs", []).append(git_name)
    kwargs.setdefault("outputs", []).append(storage_name)
    kwargs.setdefault("steps", []).extend(steps)

    task(task_name, **kwargs)

    return storage_name

def ko(task_name, git_name, image_repo, path, tag="$(context.build.name)", ldflags=None, **kwargs):
    """
    Build a Docker container for a Go binary using ko.
    """
    image_name = image_resource("image-" + task_name, url = image_repo + ":" + tag)

    env = [
        k8s.corev1.EnvVar(name = "GO111MODULE", value = "on"),
        k8s.corev1.EnvVar(name = "KO_DOCKER_REPO", value = "ko.local")
    ]

    if ldflags:
        env.append(k8s.corev1.EnvVar(name = "GOFLAGS", value = "-ldflags={}".format(ldflags)))

    kwargs.setdefault("inputs", []).append(git_name)
    kwargs.setdefault("outputs", []).append(image_name)
    kwargs.setdefault("steps", []).extend([
        buildkit_container(
            name = "build",
            image = "gcr.io/tekton-releases/dogfooding/ko:latest",
            command = [
                "ko",
                "publish",
                "--oci-layout-path=$(resources.outputs.{}.path)".format(image_name),
                "--push=false",
                path
            ],
            env = env,
            workingDir = git_checkout_dir(git_name),
            output_paths = ["$(resources.outputs.{}.path)".format(image_name)]
        ),
        k8s.corev1.Container(
            name = "push",
            image = "gcr.io/tekton-releases/dogfooding/skopeo:latest",
            command = [
                "skopeo",
                "copy",
                "oci:$(resources.outputs.{}.path)/".format(image_name),
                "docker://$(resources.outputs.{}.url)".format(image_name)
            ]
        )
    ])

    task(task_name, **kwargs)

    return image_name
