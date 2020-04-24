# vi:syntax=python

__doc__ = """
# K8s

This module provides convenience functions related to Kubernetes.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/k8s@0.0.6", "secret_var")
```

"""

def secret_var(name, key):
    """
    Convenience function for adding an environment variable from a Kubernetes secret.

    Example usage: `k8s.corev1.EnvVar(name = "GITHUB_TOKEN", valueFrom = secretVar("scmtoken", "password"))`
    """
    return k8s.corev1.EnvVarSource(
        secretKeyRef = k8s.corev1.SecretKeySelector(
            localObjectReference = k8s.corev1.LocalObjectReference(name = name),
            key=key
        )
    )

def sanitize(name):
    """
    Sanitize a name for passing in to Kubernetes / Dispatch.
    """
    return ''.join([c if c.isalnum() else '-'  for c in name.strip().elems()]).lower()
