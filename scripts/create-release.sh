#!/usr/bin/env bash

set -eu -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$SCRIPT_DIR/.."

version=${1:-}
if [[ -z "$version" ]]; then
    echo "USAGE: $0 version" 2>/dev/null
    exit 1
fi
[[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-?)([^+]*)(\+?)(.*)$ ]]
declare -a ver; ver=("${BASH_REMATCH[@]:1}")

if [[ "$(git symbolic-ref --short HEAD)" != "master" ]]; then
    echo "must be on master branch" 2>/dev/null
    exit 1
fi

sed -i direnvrc \
    -e 's!\(declare major=\).*\( # UPDATE(nix-direnv version)\)!\1'"${ver[0]@Q} minor=${ver[1]@Q} patch=${ver[2]@Q}"'\2!'

sed -i README.md template/.envrc \
    -e 's!\(nix-direnv/\).*\(/direnvrc\)!\1'"${version}"'\2!' \
    -e 's?\( ! nix_direnv_version \)[0-9.]\+\(; \)?\1'"${version}"'\2?'
git add README.md direnvrc
git commit -m "bump version ${version}"
git tag -e "${version}"

echo "now run 'git push --tags origin master && scripts/update-checksum.sh'"
