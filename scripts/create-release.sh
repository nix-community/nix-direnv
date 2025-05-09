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

waitForPr() {
  local pr=$1
  while true; do
    if gh pr view "$pr" | grep -q 'MERGED'; then
      break
    fi
    echo "Waiting for PR to be merged..."
    sleep 5
  done
}

sed -Ei "s!(version = ).*!\1\"$version\";!" default.nix
sed -Ei "s!(NIX_DIRENV_VERSION=).*!\1$version!" direnvrc

sed -i README.md templates/flake/.envrc \
  -e 's!\(nix-direnv/\).*\(/direnvrc\)!\1'"${version}"'\2!' \
  -e 's?\( ! nix_direnv_version \)[0-9.]\+\(; \)?\1'"${version}"'\2?'
git add README.md direnvrc templates/flake/.envrc default.nix
git commit -m "bump version ${version}"
git tag "${version}"
git branch -D "release-${version}" || true
git checkout -b "release-${version}"
git push origin --force "release-${version}"
gh pr create \
  --base master \
  --head "release-${version}" \
  --title "Release ${version}" \
  --body "Release ${version} of nix-direnv"

gh pr merge --auto "release-${version}"

waitForPr "release-${version}"
git push origin "$version"

sha256=$(direnv fetchurl "https://raw.githubusercontent.com/nix-community/nix-direnv/${version}/direnvrc" | grep -m1 -o 'sha256-.*')
sed -i README.md templates/flake/.envrc -e "s!sha256-.*!${sha256}\"!"
git add README.md templates/flake/.envrc
git commit -m "update fetchurl checksum"
git push origin --force "release-${version}"
gh pr create \
  --base master \
  --head "release-${version}" \
  --title "Update checksums for release ${version} of nix-direnv" \
  --body "Update checksums for release ${version} of nix-direnv"
gh pr merge --auto "release-${version}"
waitForPr "release-${version}"

echo "You can now create a release at https://github.com/nix-community/nix-direnv/releases for version ${version}"
