
# K8s

This module provides convenience functions related to Kubernetes.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/k8s@0.0.5", "secret_var")
```


### secret_var(name, key)


Convenience function for adding an environment variable from a Kubernetes secret.

Example usage: `k8s.corev1.EnvVar(name="GITHUB_TOKEN", valueFrom=secret_var("scmtoken", "password"))`


### host_path_volume(path, type)


Convenience function for adding a hosh path volume.

Example usage: `k8s.corev1.Volume(name="my-volume", volumeSource=host_path_volume("/home", "Directory"))`


### secret_volume(name, mode)


Convenience function for adding a volume from a Kubernetes secret.

Example usage: `k8s.corev1.Volume(name="my-volume", volumeSource=secret_volume("my-secret"))`


### sanitize(name)


Sanitize a name for passing in to Kubernetes / Dispatch.



