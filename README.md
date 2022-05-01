# nix-direnv

![Test](https://github.com/nix-community/nix-direnv/workflows/Test/badge.svg)

A faster, persistent implementation of `direnv`'s `use_nix`,
to replace the built-in one.

Prominent features:

- significantly faster after the first run by caching the `nix-shell` environment
- prevents garbage collection of build dependencies by symlinking the resulting
  shell derivation in the user's `gcroots` (Life is too short to lose
  your project's build cache if you are on a flight with no internet connection)

## Why not use `lorri` instead?

Compared to [lorri](https://github.com/nix-community/lorri),
nix-direnv is simpler (and requires no external daemon) and supports flakes.
Additionally, lorri can sometimes re-evaluate the entirety of nixpkgs on every change
(leading to perpetual high CPU load).

## Installation

> **Heads up**: nix-direnv requires a modern Bash and GNU Grep.
> MacOS ships with outdated or non-GNU versions of these tools,
> As a work-around we suggest that macOS users install `direnv`/`grep` via Nix or Homebrew.
> Discussion of these problems can be found
> [here](https://github.com/nix-community/nix-direnv/issues/3).

There are different ways to install nix-direnv, pick your favourite:

<details>
  <summary> Via home-manager (Recommended)</summary>
### Via home-manager

Note that while the home-manager integration is recommended,
some use cases require the use of features only present in some versions of nix-direnv.
It is much harder to control the version of nix-direnv installedwith this method.
If you require such specific control, please use another method of installing nix-direnv.

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

**Optional**: To protect your nix-shell against garbage collection
you also need to add these options to your Nix configuration.

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

```Nix
keep-derivations = true
keep-outputs = true
```

</details>
<details>
  <summary>Direnv's source_url</summary>

### Direnv source_url

Put the following lines in your `.envrc`:

```bash
if ! has nix_direnv_version || ! nix_direnv_version 2.1.0; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.1.0/direnvrc" "sha256-FAT2R9yYvVg516v3LiogjIc8YfsbWbMM/itqWsm5xTA="
fi
```

</details>

<details>
  <summary>Via configuration.nix in NixOS</summary>

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
  # if you also want support for flakes 
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

</details>

<details>
<summary>With nix-env</summary
### With nix-env

As **non-root** user do the following:

```console
nix-env -f '<nixpkgs>' -iA nix-direnv
```

Then add nix-direnv to `$HOME/.direnvrc`:

```bash
source $HOME/.nix-profile/share/nix-direnv/direnvrc
```

You also need to set `keep-outputs` and `keep-derivations` to nix.conf
as described in the installation via home-manager section.

</details>

<details>
  <summary>From source</summary>
### From source

Clone the repository to some directory
and then source the direnvrc from this repository in your own `~/.direnvrc`
or `~/.config/direnv/direnvrc`:

```bash
# put this in ~/.direnvrc or ~/.config/direnv/direnvrc
source $HOME/nix-direnv/direnvrc
```

You also need to set `keep-outputs` and `keep-derivations` to nix.conf 
as described in the installation via home-manager section.

</details>

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

If you haven't used direnv before,
make sure to [hook it into your shell](https://direnv.net/docs/hook.html) first.

### Using a non-standard file name

You may use a different file name than `shell.nix` or `default.nix`
by passing the file name in `.envrc`, e.g.:

```console
$ echo "use nix foo.nix" >> .envrc
```

## Flakes support

nix-direnv also comes with an alternative `use_flake` implementation.
The code is tested and does work but the upstream flake api is not finalized,
so we we cannot guarantee stability after an nix upgrade.

Like `use_nix`,
our `use_flake` will prevent garbage collection of downloaded packages, 
including flake inputs.

### Creating a new flake-native project

This repository ships with a [flake template](https://github.com/nix-community/nix-direnv/tree/master/template).
which provides a basic flake with devShell integration and a basic `.envrc`.

To make use of this template, you may issue the following command:

```console
$ nix flake new -t github:nix-community/nix-direnv <desired output path>

```

### Integrating with a existing flake

```console
$ echo "use flake" >> .envrc && direnv allow

```

The `use flake` line also takes an additional arbitrary flake parameter,
so you can point at external flakes as follows:

```bash
use flake ~/myflakes#project
```

### Advanced usage

#### use flake

Under the covers, `use_flake` calls `nix print-dev-env`.
The first argument to the `use_flake` function is the flake expression to use,
and all other arguments are proxied along to the call to `print-dev-env`.
You may make use of this fact for some more arcane invocations.

For instance, if you have a flake that needs to be called impurely under some conditions,
you may wish to pass `--impure` to the `print-dev-env` invocation
so that the environment of the calling shell is passed in.

You can do that as follows:

```console
$ echo "use flake . --impure" > .envrc
$ direnv allow
```

#### use nix

Like `use flake`, `use nix` now uses `nix print-dev-env`.
Due to historical reasons, the argument parsing emulates `nix shell`.

This leads to some limitations in what we can reasonably parse.

Currently, all single-word arguments and some well-known double arguments 
will be interpeted or passed along.

##### Known arguments

- `-p`: Starts a list of packages to install; consumes all remaining arguments
- `--include` / `-I`: Add the following path to the list of lookup locations for `<...>` file names
- `--attr` / `-A`: Specify the output attribute to utilize

`--command`, `--run`, `--exclude`, `--pure`, `-i`, and `--keep` are explicitly ignored.

All single word arguments (`-j4`, `--impure` etc) 
are passed to the underlying nix invocation.

## General direnv tips

- [Changing where direnv stores its cache](https://github.com/direnv/direnv/wiki/Customizing-cache-location)
- [Quickly setting up direnv in a new nix project](https://github.com/nix-community/nix-direnv/wiki/Shell-integration)

## Other projects in the field

- [lorri](https://github.com/nix-community/lorri)
- [sorri](https://github.com/nmattia/sorri)
- [nixify](https://github.com/kalbasit/nur-packages/blob/master/pkgs/nixify/envrc)
- [lorelei](https://github.com/shajra/direnv-nix-lorelei)
