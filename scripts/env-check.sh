#!/usr/bin/env bash

set -e

if [[ "$#" -lt 1 ]]; then
    echo "Usage: $(basename "$0") <repo> [env_prefix (default: NSM_)]"
    exit 1
fi

repo="$(readlink -e "$1")"
env_prefix="${2:-NSM_}"
cmd_name="cmd"


is_in_order() {
    local -a arr
    mapfile -t arr < <(echo -en "${1}\n${2}" | sort)

    if [[ "${arr[0]}" == "$1" ]]; then
        return 0
    fi
    return 1
}

print_mismatch() {
    echo "Mismatch, no ${1} environment variable found in ${2}"
}

build_cmd() {
    local -r repo="$1"
    local -r output="$2"
    pushd . &>/dev/null
    cd "$repo"
    go build -o "$output" .
    popd &>/dev/null
}


declare -a readme_envs
mapfile -t readme_envs < <(grep -Eo "${env_prefix}\w+" "${repo}/README.md" | uniq | sort)


build_cmd "$repo" "$cmd_name"
declare -a cmd_envs
# Since this runs on "ubuntu-runner" I can be sure that no env vars are set and cmd fails
mapfile -t cmd_envs < <( "${repo}/${cmd_name}" 2>&1 | grep -Eo "${env_prefix}\w+" | uniq | sort)


i=0
j=0
fail=0
while true; do

    if [[ "$i" -ge "${#cmd_envs[@]}" ]]; then
        break
    elif [[ "$j" -ge "${#readme_envs[@]}" ]]; then
        break
    elif [[ "${cmd_envs[$i]}" == "${readme_envs[$j]}" ]]; then
        ((i+=1));((j+=1))
    elif is_in_order "${cmd_envs[$i]}" "${readme_envs[$j]}" ; then
        print_mismatch "${cmd_envs[$i]}" "README.md"
        ((i+=1))
        fail=1
    else
        print_mismatch "${readme_envs[$j]}" "$cmd_name"
        ((j+=1))
        fail=1
    fi
done

for ((;i<${#cmd_envs[@]};++i)); do
    print_mismatch "${cmd_envs[$i]}" "README.md"
done
for ((;j<${#readme_envs[@]};++j)); do
    print_mismatch "${readme_envs[$j]}" "$cmd_name"
done


exit "$fail"
