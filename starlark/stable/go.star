# vi:syntax=python

load("github.com/mesosphere/dispatch-catalog/starlark/stable/pipeline@master", "imageResource", "storageResource", "resourceVar")
load("github.com/mesosphere/dispatch-catalog/starlark/experimental/buildkit@master", "buildkitContainer")

__doc__ = """
# Go

Provides methods for building and testing Go modules.

Import URL: `github.com/mesosphere/dispatch-catalog/starlark/stable/go`
"""

def go_test(git, name, paths=None, image="golang:1.13.0-buster", **kwargs):
    """
    Run Go tests and generate a coverage report.
    """

    if not paths:
        paths = []

    taskName = "{}-test".format(name)

    task(taskName, inputs=[git] + kwargs.get("inputs", []), outputs=[ storageResource(taskName) ], steps=[
        buildkitContainer(
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

def go(git, name, ldflags=None, os=None, image="golang:1.13.0-buster", **kwargs):
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
        steps.append(buildkitContainer(
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

    task(taskName, inputs=[git] + kwargs.get("inputs", []), outputs=[storageResource(taskName)], steps=steps, **kwargs)
    return taskName

def ko(git, name, ko_docker_repo, *args, ldflags=None, ko_image="mesosphere/ko:1.0.0", inputs=None, tags=None, **kwargs):
    """
    Build a Docker container for a Go binary using ko.
    """
    taskName = "{}-ko".format(name)

    imageResource(taskName,
        url="{}{}:$(context.build.name)".format(name, ko_docker_repo),
        digest="$(inputs.resources.{}.digest)".format(taskName))

    env = [
        k8s.corev1.EnvVar(name="GO111MODULE", value="on"),
        k8s.corev1.EnvVar(name="KO_DOCKER_REPO", value=ko_docker_repo),
    ]

    if ldflags:
        env.append(k8s.corev1.EnvVar(name="GOFLAGS", value="-ldflags={}".format(ldflags)))

    if not tags:
        tags = "$(context.build.name)"

    task(taskName, inputs=[git]+(inputs or []), outputs=[taskName], steps=[
        buildkitContainer(
            name="ko-build",
            image="mesosphere/ko@{}".format(resourceVar(ko_image, "digest")),
            command=[
                "ko", "publish", "--oci-layout-path=./image-output",
                "--base-import-paths", "--tags", tags, "./cmd/{}".format(name)
            ],
            env=env,
            workingDir="/workspace/{}".format(git)
        ),
        k8s.corev1.Container(
            name="copy-digest",
            image="alpine",
            workingDir="/workspace/{}".format(git),
            command=[ "cp", "./image-output/index.json", "/workspace/output/{}".format(taskName) ]
        )
    ], **kwargs)

    return taskName
