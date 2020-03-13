#!starlark
# vi:syntax=python

def clean(name):
    return name.replace("/", "-").replace(":", "-").replace(".", "-")
