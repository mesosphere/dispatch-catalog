#!/usr/bin/env sh

function build {
    mkdir -p ./docs/starlark/$1

    cat > ./docs/starlark/$1/README.md <<EOF
# $1 Starlark Modules

EOF

    for file in $(find starlark/$1 -name '*.star' -print | sed 's/[.]star$//g'); do
        mkdir -p ./docs/$(dirname $file)
        dispatch ci gen-doc --file ./$file.star > ./docs/$file.md
        echo "* [$(basename $file)]($(realpath --relative-to docs/starlark/ $file))" >> docs/starlark/README.md
        echo "* [$(basename $file)]($(realpath --relative-to docs/starlark/$1 $file))" >> docs/starlark/$1/README.md
    done
}

rm -rf docs/starlark
mkdir docs/starlark/

cat > docs/starlark/README.md <<EOF
# Starlark Standard Library

The official Starlark standard library for [Dispatch](https://docs.d2iq.com/ksphere/dispatch/latest/).

## Stable modules

EOF

build stable

echo -e "\n## Experimental modules\n" >> docs/starlark/README.md

build experimental
