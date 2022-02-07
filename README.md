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

```Nix
{ pkgs, ... }:

{
  # ...other config, other config...

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  # optional for nix flakes support in home-manager 21.11, not required in home-manager unstable or 22.05
  programs.direnv.nix-direnv.enableFlakes = true;

  programs.bash.enable = true;
  # OR
  programs.zsh.enable = true;
  # Or any other shell you're using.
}
```

Optional: To protect your nix-shell against garbage collection you also need to add these options to your Nix configuration.

If you are on NixOS also add the following lines to your `/etc/nixos/configuration.nix`:

```Nix
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

```Nix
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
  # if you also want support for flakes (this makes nix-direnv use the
  # unstable version of nix):
  nixpkgs.overlays = [
    (self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; } )
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

```bash
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

Put the following lines in your `.envrc`:

```bash
if ! has nix_direnv_version || ! nix_direnv_version 1.6.0; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/1.6.0/direnvrc" "sha256-FqqbUyxL8MZdXe5LkMgtNo95raZFbegFpl5k2+PrCow="
fi
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

If you haven't used direnv before, make sure to [hook it into your shell](https://direnv.net/docs/hook.html) first.

### Using a non-standard file name
You may use a different file name than `shell.nix` or `default.nix` by passing the file name in `.envrc`, e.g.:
```console
$ echo "use nix foo.nix" >> .envrc
```

## Flakes support

nix-direnv also comes with a flake alternative. The code is tested and works however
since future nix versions might change their api regarding this feature we cannot
guarantee stability after an nix upgrade.
Likewise `use_nix` the `use_flake` implementation will prevent garbage
collection of downloaded packages and also for flake inputs.

You can run `nix flake new -t github:nix-community/nix-direnv` to get [this](https://github.com/nix-community/nix-direnv/tree/master/template) project template.
or just add:

```
$ echo "use flake" >> .envrc
$ direnv allow
```

in case the project already comes with a `flake.nix`.
Optionally if you do not want `flake.nix` to be part of the current directory repo,
you can specify an arbitrary flake expression as parameter such as:

```console
use flake ~/myflakes#project
```

### Advanced usage

Under the covers, `use_flake` calls `nix print-dev-env`.
The first argument to the `use_flake` function is the flake expression to use,
and all other arguments are proxied along to the call to `print-dev-env`.
You may make use of this fact for some more arcane invocations.

For instance, if you have a flake that needs to be called impurely under some conditions,
you may wish to pass `--impure` to the `print-dev-env` invocation
so that the environment of the calling shell is passed in.

You can do that as follows:

```
$ echo "use flake . --impure" > .envrc
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

## Shell integration

To quickly add a `default.nix`/`flake.nix` to a project you can put the following snippets in your `.bashrc`/`.zshrc`:

```bash
nixify() {
  if [ ! -e ./.envrc ]; then
    echo "use nix" > .envrc
    direnv allow
  fi
  if [[ ! -e shell.nix ]] && [[ ! -e default.nix ]]; then
    cat > default.nix <<'EOF'
with import <nixpkgs> {};
mkShell {
  nativeBuildInputs = [
    bashInteractive
  ];
}
EOF
    ${EDITOR:-vim} default.nix
  fi
}

flakify() {
  if [ ! -e flake.nix ]; then
    nix flake new -t github:nix-community/nix-direnv .
  elif [ ! -e .envrc ]; then
    echo "use flake" > .envrc
    direnv allow
  fi
  ${EDITOR:-vim} flake.nix
}

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
  A different problem is that it might trigger mass-rebuilds when the same nixpkgs
  checkout is pointed to something like staging.
- No additional daemon or services required: The codesize is small enough that it can be vendored
  into a project itself.

## Other projects in the field

- [lorri](https://github.com/nix-community/lorri)
- [sorri](https://github.com/nmattia/sorri)
- [nixify](https://github.com/kalbasit/nur-packages/blob/master/pkgs/nixify/envrc)
- [direnv-nix-lorelei](https://github.com/shajra/direnv-nix-lorelei)
