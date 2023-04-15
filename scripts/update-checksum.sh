#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$SCRIPT_DIR/.."

tag=$(git describe --tags | cut -d- -f1)
sha256=$(direnv fetchurl "https://raw.githubusercontent.com/nix-community/nix-direnv/${tag}/direnvrc" | grep -m1 -o 'sha256-.*')

sed -i README.md templates/flake/.envrc -e "s!sha256-.*!${sha256}\"!"
git add README.md templates/flake/.envrc
git commit -m "update fetchurl checksum"
echo "Now run: git push"
echo "And create a release at https://github.com/nix-community/nix-direnv/releases for version ${tag}"
