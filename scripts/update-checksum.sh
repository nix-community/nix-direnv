#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$SCRIPT_DIR/.."

tag=$(curl --silent "https://api.github.com/repos/nix-community/nix-direnv/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
sha256=$(direnv fetchurl "https://raw.githubusercontent.com/nix-community/nix-direnv/${tag}/direnvrc" | grep -m1 -o 'sha256-.*')

sed -i README.md template/.envrc -e "s!sha256-.*!${sha256}\"!"
git add README.md template/.envrc
git commit -m "update fetchurl checksum"
#git push
