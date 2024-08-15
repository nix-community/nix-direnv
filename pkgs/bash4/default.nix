{ bash, fetchurl }:

bash.overrideAttrs (_old: {
  name = "bash-4.4";
  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/bash/bash-4.4.tar.gz";
    hash = "sha256-2GszksEgLo/1pCOzAuYoTbf49DXqnzm1sbIP06w238s=";
  };

  # generated with update-patch-set.sh from nixpkgs/pkgs/shells/bash
  patches = import ./bash-4.4-patches.nix (
    nr: sha256:
    fetchurl {
      url = "mirror://gnu/bash/bash-4.4-patches/bash44-${nr}";
      inherit sha256;
    }
  );
})
