#!/usr/bin/env bash

if [ $1 ]; then
    echo "ONYX_VERSION = \"$1\"" > src/compiler/onyx/version_number.cr
    git tag "$1"
    $0
else
    cat src/compiler/onyx/version_number.cr
fi
