### dindTask(*args, **kwargs)


Defines a new docker-in-docker task in a pipeline. The steps are run in the default `mesosphere/dispatch-dind` image unless an alternative image is specified.

Example usage:

```sh
dindTask("test", inputs=["git"], steps=[k8s.corev1.Container(
    name="test",
    command=["docker", "run", "-v", "/workspace/git:/workspace/git", "-w", "/workspace/git", "golang:1.13.0-buster", "go", "test", "./..."],
)])
```



