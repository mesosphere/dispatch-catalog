# vi:syntax=python

load("/starlark/stable/pipeline", "git_checkout_dir", "image_resource", "storage_resource")
load("/starlark/stable/path", "basename")
load("/starlark/stable/k8s", "sanitize")
load("/starlark/experimental/buildkit", "buildkit_container")

__doc__ = """
# Go

Provides methods for building and testing Go modules.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/go@0.0.6", "ko")
```

"""

def go_test(git, name, paths=None, image="golang:1.13.0-buster", inputs=None, **kwargs):
    """
    Run Go tests and generate a coverage report.
    """

    if not paths:
        paths = []

    taskName = "{}-test".format(name)

    task(taskName, inputs=[git] + (inputs or []), outputs=[ storage_resource(taskName) ], steps=[
        buildkit_container(
            name="go-test-{}".format(name),
            image=image,
            command=[ "go", "test", "-v", "-coverprofile", "/workspace/output/{}/coverage.out".format(taskName) ] + paths,
            env=[ k8s.corev1.EnvVar(name="GO111MODULE", value="on") ],
            workingDir="/workspace/{}".format(git)
        ),
        k8s.corev1.Container(
            name="coverage-report-{}".format(name),
            image=image,
            workingDir="/workspace/{}/".format(git),
            command=[
                "sh", "-c",
                """
                go tool cover -func /workspace/output/{}/coverage.out | tee /workspace/output/{}/coverage.txt
                cp /workspace/output/{}/coverage.txt coverage.txt
                git add coverage.txt
                git diff --cached coverage.txt
                """.format(taskName, taskName, taskName)
            ],
            env=[ k8s.corev1.EnvVar(name="GO111MODULE", value="on") ],
        )], **kwargs)

    return taskName

def go(task_name, git_name, path, ldflags=None, os=["linux"], arch=["amd64"], **kwargs):
    """
    Build Go binaries.
    """
    # TODO(chhsiao): Because the location is deterministic, artifacts will be overwritten by
    # different runs. We should introduce a mechanism to avoid this.
    storage_name = "storage-" + sanitize(path)[-55:]
    storage_resource(storage_name, location = "s3://artifacts/{}/".format(storage_name))

    command = ["go", "build"]

    if ldflags:
        command += ["-ldflags", ldflags]

    steps = []
    for goos in os:
        for goarch in arch:
            steps.append(buildkit_container(
                name = "go-build-{}_{}".format(goos, goarch),
                image = "golang:1.14",
                command = command + [
                    "-o",
                    "$(resources.outputs.{}.path)/{}_{}/{}".format(storage_name, goos, goarch, basename(path)),
                    path
                ],
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
    image_name = image_resource("image-" + sanitize(image_repo)[-57:], url = image_repo + ":" + tag)

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
