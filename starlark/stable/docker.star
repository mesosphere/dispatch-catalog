#!starlark
# vi:syntax=python

def dindTask(*args, **kwargs):
    volumes = kwargs.get('volumes', [])
    volumes.append(volume("docker", emptyDir=k8s.corev1.EmptyDirVolumeSource()))
    volumes.append(volume("modules", hostPath=k8s.corev1.HostPathVolumeSource(path="/lib/modules", type="Directory")))
    volumes.append(volume("cgroups", hostPath=k8s.corev1.HostPathVolumeSource(path="/sys/fs/cgroup", type="Directory")))
    kwargs['volumes'] = volumes
    for index, step in enumerate(kwargs.get('steps', [])):
        if step.image == "":
            step.image = dind_image
        step.volumeMounts.append(k8s.corev1.VolumeMount(name="docker", mountPath="/var/lib/docker"))
        step.volumeMounts.append(k8s.corev1.VolumeMount(name="modules", mountPath="/lib/modules", readOnly=True))
        step.volumeMounts.append(k8s.corev1.VolumeMount(name="cgroups", mountPath="/sys/fs/cgroup"))
        step.env.append(k8s.corev1.EnvVar(name="DOCKER_RANGE", value="172.17.1.1/24"))
        step.securityContext = k8s.corev1.SecurityContext(privileged=True)
        kwargs['steps'][index] = step
    return task(*args, **kwargs)
