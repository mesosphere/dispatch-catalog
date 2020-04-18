# vi:syntax=python

load("/starlark/stable/pipeline", "git_checkout_dir", "image_resource", "sanitize", "storageResource", "resourceVar")
load("/starlark/experimental/buildkit", "buildkit_container")

__doc__ = """
# Go

Provides methods for building and testing Go modules.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/go@0.0.4", "ko")
```

"""

def go_test(git, name, paths=None, image="golang:1.13.0-buster", inputs=None, **kwargs):
    """
    Run Go tests and generate a coverage report.
    """

    if not paths:
        paths = []

    taskName = "{}-test".format(name)

    task(taskName, inputs=[git] + (inputs or []), outputs=[ storageResource(taskName) ], steps=[
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

def go(git, name, ldflags=None, os=None, image="golang:1.13.0-buster", inputs=None, **kwargs):
    """
    Build a Go binary.
    """

    if not os:
        os = ['linux']

    taskName = "{}-build".format(name)


    command = [ "go", "build" ]

    if ldflags:
        command += ["-ldflags", ldflags]

    steps = []

    for os_name in os:
        steps.append(buildkit_container(
            name="go-build-{}".format(os_name),
            image=image,
            command=command + [
                "-o", "/workspace/output/{}/{}_{}".format(taskName, name, os_name), "./cmd/{}".format(name)
            ],
            env=[
                k8s.corev1.EnvVar(name="GO111MODULE", value="on"),
                k8s.corev1.EnvVar(name="GOOS", value=os_name),
            ],
            workingDir="/workspace/{}".format(git)
        ))

    task(taskName, inputs=[git] + (inputs or []), outputs=[storageResource(taskName)], steps=steps, **kwargs)
    return taskName

def ko(task_name, git_name, image_repo, package, tag="$(context.build.name)", ldflags=None, **kwargs):
    """
    Build a Docker container for a Go binary using ko.
    """
    image_name = image_resource("image-" + sanitize(image_repo)[-57:], url = image_repo + ":" + tag)

    env = [
        k8s.corev1.EnvVar(name = "GO111MODULE", value = "on"),
        k8s.corev1.EnvVar(name = "KO_DOCKER_REPO", value = "-"),
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
                package
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
