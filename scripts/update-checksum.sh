#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$SCRIPT_DIR/.."

tag=$(git describe)
sha256=$(direnv fetchurl "https://raw.githubusercontent.com/nix-community/nix-direnv/${tag}/direnvrc" | grep -m1 -o 'sha256-.*')

sed -i README.md -e "s!sha256-[^\"]+!sha256-${sha256}!"
git add README.md
git commit -m "README: update fetchurl checksum"
git push
