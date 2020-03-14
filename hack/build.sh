#!/usr/bin/env sh

rm -rf doc/starlark

find starlark -name '*.star' -print | sed 's/[.]star$//g' |xargs -i bash -c 'mkdir -p ./doc/`dirname {}` && dispatch ci gen-doc --file ./{}.star > ./doc/{}.md'
