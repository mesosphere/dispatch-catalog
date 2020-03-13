#!starlark
# vi:syntax=python

def push(**kwargs):
    return p.Condition(push=p.PushCondition(**kwargs))

def tag(**kwargs):
    return p.Condition(tag=p.TagCondition(**kwargs))

def pullRequest(**kwargs):
    return p.Condition(pull_request=p.PullRequestCondition(**kwargs))

def gitResource(name, url="$(context.git.url)", revision="$(context.git.commit)", pipeline=None):
    return resource(name, type = "git", params = {
        "url": url,
        "revision": revision,
    }, pipeline=pipeline)

def imageResource(name, url, digest, pipeline=None):
    return resource(name, type = "image", params = {
        "url": url,
        "digest": digest
    }, pipeline=pipeline)

def volume(name, **kwargs):
    return k8s.corev1.Volume(name=name, volumeSource=k8s.corev1.VolumeSource(**kwargs))

def resourceVar(name, key):
    return "$(inputs.resources.{}.{})".format(name, key)

def secretVar(name, key):
    return k8s.corev1.EnvVarSource(secretKeyRef=k8s.corev1.SecretKeySelector(localObjectReference=k8s.corev1.LocalObjectReference(name=name), key=key))

def storageResource(name):
    resource(name, type = "storage", params = {
        "type": "gcs",
        "location": "s3://artifacts",
    }, secrets = {
        "BOTO_CONFIG": k8s.corev1.SecretKeySelector(key = "boto", localObjectReference = k8s.corev1.LocalObjectReference(name = "s3-config"))
    })

    return name
