# vi:syntax=python

load("/starlark/stable/k8s", "host_path_volume")

__doc__ = """
# Docker

Provides methods for using Docker.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/docker@0.0.5", "dind_task")
```

"""

def dind_task(name, steps=[], volumes=[], **kwargs):
    """
    Defines a new docker-in-docker task in a pipeline. The steps are run in the default `mesosphere/dispatch-dind` image unless an alternative image is specified.

    Example usage:

    ```python
    dindTask("test", inputs=["git"], steps=[k8s.corev1.Container(
        name="test",
        command=["docker", "run", "-v", "/workspace/git:/workspace/git", "-w", "/workspace/git", "golang:1.13.0-buster", "go", "test", "./..."],
    )])
    ```
    """

    volumes = volumes + [
        k8s.corev1.Volume(name="docker"),
        k8s.corev1.Volume(name="modules", volumeSource=host_path_volume("/lib/modules", "Directory")),
        k8s.corev1.Volume(name="cgroups", volumeSource=host_path_volume("/sys/fs/cgroup", "Directory"))
    ]

    for index, step in enumerate(steps):
        if step.image == "":
            step.image = "mesosphere/dispatch-dind:1.1.0"
        step.volumeMounts.extend([
            k8s.corev1.VolumeMount(name="docker", mountPath="/var/lib/docker"),
            k8s.corev1.VolumeMount(name="modules", mountPath="/lib/modules", readOnly=True),
            k8s.corev1.VolumeMount(name="cgroups", mountPath="/sys/fs/cgroup")
        ])
        step.env.append(k8s.corev1.EnvVar(name="DOCKER_RANGE", value="172.17.1.1/24"))
        step.securityContext=k8s.corev1.SecurityContext(privileged=True)

    return task(name, volumes=volumes, steps=steps, **kwargs)

def dindTask(*args, **kwargs):
    """
    DEPRECATED: Use dind_task instead.
    """

    return dind_task(*args, **kwargs)
