# vi:syntax=python

__doc__ = """
# K8s

This module provides convenience functions related to Kubernetes.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/k8s@0.0.5", "secret_var")
```

"""

def secret_var(name, key):
    """
    Convenience function for adding an environment variable from a Kubernetes secret.

    Example usage: `k8s.corev1.EnvVar(name="GITHUB_TOKEN", valueFrom=secretVar("scmtoken", "password"))`
    """

    return k8s.corev1.EnvVarSource(
        secretKeyRef=k8s.corev1.SecretKeySelector(
            localObjectReference=k8s.corev1.LocalObjectReference(name=name),
            key=key
        )
    )

def host_path_volume(path, type):
    """
    Convenience function for adding a hosh path volume.

    Example usage: `k8s.corev1.Volume(name="my-volume", volumeSource=host_path_volume("/home", "Directory"))`
    """

    return k8s.corev1.VolumeSource(
        hostPath = k8s.corev1.HostPathVolumeSource(path=path, type=type)
    )

def secret_volume(name, mode=0o600):
    """
    Convenience function for adding a volume from a Kubernetes secret.

    Example usage: `k8s.corev1.Volume(name="my-volume", volumeSource=secret_volume("my-secret"))`
    """

    return k8s.corev1.VolumeSource(
        secret = k8s.corev1.SecretVolumeSource(secretName=name, defaultMode=mode)
    )

def sanitize(name):
    """
    Sanitize a name for passing in to Kubernetes / Dispatch.
    """

    return ''.join([c if c.isalnum() else '-'  for c in name.strip().elems()]).lower()
