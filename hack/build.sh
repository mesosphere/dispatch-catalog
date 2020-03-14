#!/usr/bin/env sh

rm -rf docs/starlark

find starlark -name '*.star' -print | sed 's/[.]star$//g' |xargs -i bash -c 'mkdir -p ./docs/`dirname {}` && dispatch ci gen-doc --file ./{}.star > ./docs/{}.md'
