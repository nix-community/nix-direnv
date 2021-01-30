# nix-direnv

![Test](https://github.com/nix-community/nix-direnv/workflows/Test/badge.svg)

A faster, persistent implementation of `direnv`'s `use_nix`, to replace the built-in one.

Prominent features:

- significantly faster after the first run by caching the `nix-shell` environment
- prevents garbage collection of build dependencies by symlinking the resulting
  shell derivation in the user's `gcroots` (Life is too short to lose
  your project's build cache if you are on a flight with no internet connection)

## Installation

There are different ways to install nix-direnv, pick your favourite:

- via home-manager (recommended)
- via configuration.nix in NixOS
- with nix-env
- from source
- with direnv source_url

### Via home-manager

In `$HOME/.config/nixpkgs/home.nix` add

```
{ pkgs, ... }:

{
  # ...other config, other config...

  programs.direnv.enable = true;
  programs.direnv.enableNixDirenvIntegration = true;
}
```

Optional: To protect your nix-shell against garbage collection you also need to add these options to your Nix configuration.

If you are on NixOS also add the following lines to your `/etc/nixos/configuration.nix`:

```
{ pkgs, ... }: {
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
}
```

On other systems with Nix add the following configuration to your `/etc/nix/nix.conf`:

```
keep-derivations = true
keep-outputs = true
```

### Via configuration.nix in NixOS

In `/etc/nixos/configuration.nix`:

```
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ direnv nix-direnv ];
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

Then source the `direnvrc` from this repository in your own `$HOME/.direnvrc`

```bash
# put this in ~/.direnvrc
source /run/current-system/sw/share/nix-direnv/direnvrc
```

### With nix-env

As **non-root** user do the following:

```console
nix-env -f '<nixpkgs>' -iA nix-direnv
```

Then add nix-direnv to `$HOME/.direnvrc`:

```
source $HOME/.nix-profile/share/nix-direnv/direnvrc
```

You also need to set `keep-outputs` and `keep-derivations` to nix.conf as described in the installation
via home-manager section.

### From source

Clone the repository to some directory

```console
$ git clone https://github.com/nix-community/nix-direnv $HOME/nix-direnv
```

Then source the direnvrc from this repository in your own `.direnvrc`

```bash
# put this in ~/.direnvrc
source $HOME/nix-direnv/direnvrc
```

You also need to set `keep-outputs` and `keep-derivations` to nix.conf as described in the installation
via home-manager section.

### Direnv source_url

Put the following line in your .envrc

```bash
source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/1.2.2/direnvrc" "sha256-phL9Ogixr0gH/KP4IvhUmebLtA/liGrmRoxYrVJnaU0="
```

## Usage example

Either add `shell.nix` or a `default.nix` to the same directory:

``` nix
# save this as shell.nix
{ pkgs ? import <nixpkgs> {}}:

pkgs.mkShell {
  nativeBuildInputs = [ pkgs.hello ];
}
```

Then add the line `use nix` to your envrc:
```console
$ echo "use nix" >> .envrc
$ direnv allow
```

## Flakes support

nix-direnv also comes with a flake alternative. The code is tested and works however
since future nix versions might change their api regarding this feature we cannot
guarantee stability after an nix upgrade.
Likewise `use_nix` the `use_flake` implementation will prevent garbage
collection of downloaded packages and also for flake inputs.

Save this file as `flake.nix`:

``` nix
{
  description = "A very basic flake";
  # Provides abstraction to boiler-code when specifying multi-platform outputs.
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.hello ];
      };
    });
}
```

Then add `use flake` to your `.envrc`:

```console
$ echo "use flake" >> .envrc
$ direnv allow
```

## Storing .direnv outside the project directory

A `.direnv` directory will be created in each `use_nix` project, which might
interact badly with backups (e.g. Dropbox) or IDEs.

Therefore it's possible to override a function called `direnv_layout_dir` in
`$HOME/.config/direnv/direnvrc` or in each project's `.envrc`.

The following example will create a unique directory name per project
in `$HOME/.cache/direnv/layouts/`:

```bash
# $HOME/.config/direnv/direnvrc
: ${XDG_CACHE_HOME:=$HOME/.cache}
declare -A direnv_layout_dirs
direnv_layout_dir() {
    echo "${direnv_layout_dirs[$PWD]:=$(
        echo -n "$XDG_CACHE_HOME"/direnv/layouts/
        echo -n "$PWD" | shasum | cut -d ' ' -f 1
    )}"
}
```
During direnv setup `direnv_layout_dir` can be called multiple times and with different values of `$PWD`
(when other `.envrc` files are included). Therefore cache its results in dictionary `direnv_layout_dirs`.

## Manually re-triggering evaluation

In some case nix-direnv does not detect if imported file has changed and still
provides the old cached values. An evaluation can be triggered by updating your
`default.nix`, `shell.nix` or `flake.nix`, depending on what is used:

```console
# choose one
$ touch default.nix
$ touch shell.nix
$ touch flake.nix
```

## Known Bugs

At the moment `nix-direnv` depends on GNU Grep and a modern Bash version.
This might lead to [problems](https://github.com/nix-community/nix-direnv/issues/3) on macOS.
As a work-around we suggest that macOS users install `direnv`/`grep` via Nix or Homebrew.

## Why not use `lorri` instead?

- nix-direnv has flakes support.
- High CPU load/resource usage in some cases: When nixpkgs in `NIX_PATH` is
  pointed to a directory, i.e. a git checkout, Lorri will try to evaluate
  nixpkgs everytime something changes causing high cpu load. Nix-direnv
  compromises between performance and correctness, and only re-evaluates direnv
  if either the project-specific `default.nix` / `shell.nix` changes, or if
  there is a new commit added to `nixpkgs`. A re-evaluation can be also
  triggered by using `touch .envrc` in the same project.
- No additional daemon or services required: The codesize is small enough that it can be vendored
  into a project itself.

## Other projects in the field

- [lorri](https://github.com/target/lorri)
- [sorri](https://github.com/nmattia/sorri)
- [nixify](https://github.com/kalbasit/nur-packages/blob/master/pkgs/nixify/envrc)
- [direnv-nix-lorelei](https://github.com/shajra/direnv-nix-lorelei)
