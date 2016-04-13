#!/usr/bin/env bash

echo "ONYX_VERSION = \"$1\"" > src/compiler/onyx/version_number.cr
git tag "$1"
