
# Docker

Provides methods for using Docker.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/docker@0.0.5", "dind_task")
```


### dindTask(*args, **kwargs)


DEPRECATED: Use dind_task instead.


### dind_task(name, steps, volumes, **kwargs)


Defines a new docker-in-docker task in a pipeline. The steps are run in the default `mesosphere/dispatch-dind` image unless an alternative image is specified.

Example usage:

```python
dind_task("test", inputs=["git"], steps=[k8s.corev1.Container(
    name="test",
    args=["docker", "run", "-v", "/workspace/git:/workspace/git", "-w", "/workspace/git", "golang:1.13.0-buster", "go", "test", "./..."],
)])
```



