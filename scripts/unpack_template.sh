#!/usr/bin/env bash

set -e -o pipefail


prefix_tmpl="__PREFIX__"
modulename_tmpl="__MODULENAME__"
testfile_name="env_test.go"
scriptdir="$(readlink -e "$0" | xargs dirname)"


find_prefix() {
    grep "envconfig.Usage" "$1" -r --include "*.go" --exclude "$testfile_name"| \
        sed -E 's:^.*envconfig.Usage[f]?\(.*"(.+)".*\).*$:\1:g ; t ; q5'
}

find_modulename() {
    module_path=$(grep "envconfig.Usage" "$1" -r -l --include "*.go" --exclude "$testfile_name")
    echo "$(cd "$1" && go list -m)/$(realpath -e --relative-to="$1" "$module_path")" \
        | xargs dirname
}

unpack_test() {
    prefix="$(find_prefix "$1")"
    module_name="$(find_modulename "$1")"
    testfile="${1}/${testfile_name}"

    cp "${scriptdir}/env_test.go.tmpl" "$testfile"
    sed -i "s;__PREFIX__;\"${prefix}\";" "$testfile"
    sed -i "s;__MODULENAME__;\"${module_name}\";" "$testfile"
}

if [ "$#" -lt 1 ]; then
    echo "Usage: $1 <path-to-cmd-repository>"
    exit 1
fi

unpack_test "$(readlink -e "$1")"
