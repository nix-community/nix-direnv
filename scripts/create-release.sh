#!/usr/bin/env bash

set -eu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
cd "$SCRIPT_DIR/.."

version=${1:-}
if [[ -z $version ]]; then
  echo "USAGE: $0 version" 2>/dev/null
  exit 1
fi

if [[ "$(git symbolic-ref --short HEAD)" != "master" ]]; then
  echo "must be on master branch" 2>/dev/null
  exit 1
fi

sed -Ei "s!(NIX_DIRENV_VERSION=).*!\1$version!" direnvrc

sed -i README.md templates/flake/.envrc \
  -e 's!\(nix-direnv/\).*\(/direnvrc\)!\1'"${version}"'\2!' \
  -e 's?\( ! nix_direnv_version \)[0-9.]\+\(; \)?\1'"${version}"'\2?'
git add README.md direnvrc templates/flake/.envrc
git commit -m "bump version ${version}"
git tag -e "${version}"

echo "now run 'git push --tags origin master && ./scripts/update-checksum.sh'"
