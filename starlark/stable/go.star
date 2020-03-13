#!starlark
# vi:syntax=python

load("github.com/jbarrick-mesosphere/catalog/starlark/stable/pipeline@master", "storageResource")
load("github.com/jbarrick-mesosphere/catalog/starlark/experimental/buildkit@master", "buildkitContainer")

def go_test(git, name, paths=None, **kwargs):
    if not paths:
        paths = []

    taskName = "{}-test".format(name)

    task(taskName, inputs=[git], outputs=[ storageResource(taskName) ], steps=[
        buildkitContainer(
            name="go-test-{}".format(name),
            image="golang:1.13.0-buster",
            command=[ "go", "test", "-v", "-coverprofile", "/workspace/output/{}/coverage.out".format(taskName) ] + paths,
            env=[ k8s.corev1.EnvVar(name="GO111MODULE", value="on") ],
            workingDir="/workspace/{}".format(git)
        ),
        k8s.corev1.Container(
            name="coverage-report-{}".format(name),
            image="golang:1.13.0-buster",
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

def go(git, name, ldflags=None, os=None, **kwargs):
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
            image="golang:1.13.0-buster",
            command=command + [
                "-o", "/workspace/output/{}/{}_{}".format(taskName, name, os_name), "./cmd/{}".format(name)
            ],
            env=[
                k8s.corev1.EnvVar(name="GO111MODULE", value="on"),
                k8s.corev1.EnvVar(name="GOOS", value=os_name),
            ],
            workingDir="/workspace/{}".format(git)
        ))

    task(taskName, inputs=[git], outputs=[storageResource(taskName)], steps=steps, **kwargs)
    return taskName

def ko(git, name, *args, ldflags=None, **kwargs):
    taskName = "{}-ko".format(name)

    imageResource(taskName,
        url="mesosphere/{}:$(context.build.name)".format(name),
        digest="$(inputs.resources.{}.digest)".format(taskName))

    env = [
        k8s.corev1.EnvVar(name="GO111MODULE", value="on"),
        k8s.corev1.EnvVar(name="KO_DOCKER_REPO", value="docker.io/mesosphere"),
    ]

    if ldflags:
        env.append(k8s.corev1.EnvVar(name="GOFLAGS", value="-ldflags={}".format(ldflags)))

    task(taskName, inputs=[git, ko_image], outputs=[taskName], steps=[buildkitContainer(
        name="ko-build",
        image="mesosphere/ko@{}".format(resourceVar(ko_image, "digest")),
        command=[
            "ko", "publish", "--oci-layout-path=./image-output",
            "--base-import-paths", "--tags", "$(context.build.name)", "./cmd/{}".format(name)
        ],
        env=env,
        workingDir="/workspace/{}".format(git)
    ),
    k8s.corev1.Container(
        name="copy-digest",
        image="alpine",
        workingDir="/workspace/{}".format(git),
        command=[ "cp", "./image-output/index.json", "/workspace/output/{}".format(taskName) ]
    )])

    return taskName
