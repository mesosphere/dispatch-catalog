# vi:syntax=python

load("github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline@master", "imageResource", "storageResource", "resourceVar")

__doc__ = """
# Go

Provides methods for building and testing Go modules.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/go@0.0.4", "ko")
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
        k8s.corev1.Container(
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
        steps.append(k8s.corev1.Container(
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

def ko(git, image_name, name, *args, ldflags=None, ko_image="mesosphere/ko:1.1.0-beta1", inputs=None, tag="$(context.build.name)", **kwargs):
    """
    Build a Docker container for a Go binary using ko.
    """
    taskName = "{}-ko".format(name)

    imageWithTag = "{}:{}".format(image_name, tag)

    imageResource(taskName,
        url=image_name,
        digest="$(inputs.resources.{}.digest)".format(taskName))

    env = [
        k8s.corev1.EnvVar(name="GO111MODULE", value="on"),
        k8s.corev1.EnvVar(name="KO_DOCKER_REPO", value="-"),
    ]

    if ldflags:
        env.append(k8s.corev1.EnvVar(name="GOFLAGS", value="-ldflags={}".format(ldflags)))

    task(taskName, inputs=[git]+(inputs or []), outputs=[taskName], steps=[
        k8s.corev1.Container(
            name="ko-build",
            image=ko_image,
            command=[
                "ko", "publish", "--oci-layout-path=/workspace/output/{}".format(taskName), "--push=false", "./cmd/{}".format(name)
            ],
            env=env,
            workingDir="/workspace/{}".format(git)
        ),
        k8s.corev1.Container(
            name = "push",
            image = "mesosphere/skopeo:1.1.0-beta1",
            command = [
                "skopeo", "copy", "oci:/workspace/output/{}/".format(taskName), "docker://{}".format(imageWithTag)
            ]
        ),
 
    ], **kwargs)

    return taskName
