# nix-direnv

![Test](https://github.com/nix-community/nix-direnv/workflows/Test/badge.svg)

A fast, persistent use_nix implementation for direnv.
Prominent features:

- significantly faster after the first run by caching the nix-shell environment
- prevents garbage collection of build dependencies by symlinking the resulting
  shell derivation in the user's `gcroots` (Life is too short to loose your
  build cache of your project if you are in a plane without internet connection)

## Installation via nix

Since 20.03 you can install nix-direnv via nix:

### NixOS

In `/etc/nixos/configuration.nix`:

```
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ nix-direnv ];
  # nix options for derivations to persist garbage collection
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  environment.pathsToLink = [
    "/share/nix-direnv"
  ];
}
```

Then source the direnvrc from this repository in your own `.direnvrc`

```bash
# put this in ~/.direnvrc
source $HOME/.nix-direnv/direnvrc

if [ -f /run/current-system/sw/share/nix-direnv/direnvrc ]; then
  source /run/current-system/sw/share/nix-direnv/direnvrc
fi
```

### Home-manager

In `$HOME/.config/nixpkgs/home.nix` add

```
{ pkgs, ... }:

{
  # ...other config, other config...

  programs.direnv.enable = true;
  programs.direnv.stdlib = ''
    source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
  '';
}
```

Optional: To protect your nix-shell against garbage collection you also need to add these options to your nix configuration

If you are on NixOS also add the following lines to your `/etc/nixos/configuration.nix`:

```
{ pkgs, ... }: {
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
}
```

On other systems with nix add the following configuration to your `/etc/nix/nix.conf`:

```
keep-derivations = true
keep-outputs = true
```

## Installation via nix-env

As **non-root** user do the following:

```console
nix-env -f '<nixpkgs>' -iA nix-direnv
```

Than follow the home-manager installation except for the `$HOME/.config/nixpkgs/home.nix` changes.

## Installation from source

Clone the repository to some directory

```console
$ git clone https://github.com/nix-community/nix-direnv $HOME/nix-direnv
```

Then source the direnvrc from this repository in your own `.direnvrc`

```bash
# put this in ~/.direnvrc
source $HOME/nix-direnv/direnvrc
```

## Storing .direnv outside the project directory

`.direnv` might interact badly with backups (i.e. Dropbox) or IDEs.
Therefore it's possible to override in `$HOME/.config/direnv/direnvrc` or
in own project's `.envrc` a variable called `$direnv_layout_dir`.
The following example will create a unique directory name per project
in `$HOME/.cache/direnv/layouts/`:


```bash
# $HOME/.config/direnv/direnvrc
: ${XDG_CACHE_HOME:=$HOME/.cache}
pwd_hash=$(echo -n $PWD | shasum | cut -d ' ' -f 1)
direnv_layout_dir=$XDG_CACHE_HOME/direnv/layouts/$pwd_hash
```

## Known Bugs

At the moment nix-direnv depends on gnugrep and a modern bash version.
This might lead to [problems](https://github.com/nix-community/nix-direnv/issues/3) on macOS.
As a work-around we suggest to install direnv/grep via nix or homebrew.

## Why not using lorri instead?

Lorri causes large CPU load when `$NIXPKGS` is pointed to a directory, i.e. a
git checkout. This is because it tries to watch any referenced nix file and
re-evaluates if those changes. Nix-direnv comprises between performance and
correctness and only reevaluate direnv if either the project-specific
`default.nix` / `shell.nix` changes or if there is a new commit added to
`nixpkgs`. A re-evaluation can be also triggered by using `touch shell.nix` in
the same project. Also `nix-direnv` does not require additional software besides
`direnv` + `nix` i.e. a daemon and the function could be included into the
project itself.
