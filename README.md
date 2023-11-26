# nix-direnv

![Test](https://github.com/nix-community/nix-direnv/workflows/Test/badge.svg)

A faster, persistent implementation of `direnv`'s `use_nix` and `use_flake`,
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
{
  # ...other config, other config...

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };

    bash.enable = true; # see note on other shells below
  };
}
```

Check the current [Home Manager Options](https://mipmip.github.io/home-manager-option-search/?query=direnv)
for integration with shells other than Bash. Be sure to also allow `home-manager` to
manage your shell with `programs.<your_shell>.enable = true`.

</details>
<details>
  <summary>Direnv's source_url</summary>

### Direnv source\_url

Put the following lines in your `.envrc`:

```bash
if ! has nix_direnv_version || ! nix_direnv_version 2.4.0; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.4.0/direnvrc" "sha256-XQzUAvL6pysIJnRJyR7uVpmUSZfc7LSgWQwq/4mBr1U="
fi
```

</details>

<details>
  <summary>Via system configuration on NixOS</summary>

### Via system configuration on NixOS

For NixOS 23.05+ all that's required is 

```Nix 
{
  programs.direnv.enable = true;
}
```

other available options are:

```Nix
{ pkgs, ... }: {
  #set to default values
  programs.direnv = {
    package = pkgs.direnv;
    silent = false;
    loadInNixShell = true;
    direnvrcExtra = "";
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  }
```
</details>

<details>
  <summary>With `nix-env`</summary>

### With `nix-env`

As **non-root** user do the following:

```shell
nix-env -f '<nixpkgs>' -iA nix-direnv
```

Then add nix-direnv to `$HOME/.config/direnv/direnvrc`:

```bash
source $HOME/.nix-profile/share/nix-direnv/direnvrc
```

</details>
  
  <details>
  <summary>With `nix profile`</summary>

### With `nix profile`

As **non-root** user do the following:

```shell
nix profile install nixpkgs#nix-direnv
```

Then add nix-direnv to `$HOME/.config/direnv/direnvrc`:

```bash
source $HOME/.nix-profile/share/nix-direnv/direnvrc
```

</details>

<details>
  <summary>From source</summary>

### From source

Clone the repository to some directory
and then source the direnvrc from this repository in your own 
`~/.config/direnv/direnvrc`:

```bash
# put this in ~/.config/direnv/direnvrc
source $HOME/nix-direnv/direnvrc
```

</details>

## Usage example

Either add `shell.nix` or a `default.nix` to the project directory:

``` nix
# save this as shell.nix
{ pkgs ? import <nixpkgs> {}}:

pkgs.mkShell {
  packages = [ pkgs.hello ];
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
so we we cannot guarantee stability after a nix upgrade.

Like `use_nix`,
our `use_flake` will prevent garbage collection of downloaded packages,
including flake inputs.

### Creating a new flake-native project

This repository ships with a [flake template](https://github.com/nix-community/nix-direnv/tree/master/templates/flake).
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

#### Manual reload of the nix environment

To avoid delays and time consuming rebuilds at unexpected times, you can use
nix-direnv in the "manual reload" mode. nix-direnv will then tell you when the
nix environment is no longer up to date. You can then decide yourself when you
want to reload the nix environment.

To activate manual mode, use `nix_direnv_manual_reload` in your `.envrc` like this:

```shell
nix_direnv_manual_reload
use nix # or use flake
```

To reload your nix environment, use the `nix-direnv-reload` command:

```console
$ nix-direnv-reload
```

##### Known arguments

- `-p`: Starts a list of packages to install; consumes all remaining arguments
- `--include` / `-I`: Add the following path to the list of lookup locations for `<...>` file names
- `--attr` / `-A`: Specify the output attribute to utilize

`--command`, `--run`, `--exclude`, `--pure`, `-i`, and `--keep` are explicitly ignored.

All single word arguments (`-j4`, `--impure` etc)
are passed to the underlying nix invocation.

#### Tracked files

`nix-direnv` makes a performance tradeoff
and only considers changes in a limited number of files
when deciding to update its cache.

- for `use nix` this is:
    * `~/.direnvrc`
    * `~/.config/direnv/direnvrc`
    * `.envrc`,
    * A single nix file. In order of preference:
        + The file argument to `use nix`
        + `shell.nix` if it exists
        + `default.nix` if it exists

- for `use flake` this is:
    * `~/.direnvrc`
    * `~/.config/direnv/direnvrc`
    * `.envrc`
    * `flake.nix`
    * `flake.lock`
    * `devshell.toml` if it exists

To add more files to be checked use `watch_file` like this

```shell
watch_file your-file.nix
use nix # or use flake
```

Or - if you don't mind the overhead (runtime and conceptual) of watching all nix-files:

```shell
watch_file $(find . -name "*.nix" -printf '"%p" ')
```

Note that this will re-execute direnv for any nix change,
regardless of whether that change is meaningful for the devShell in use.

`watch_file` must be invoked before either `use flake` or `use nix` to take effect.

## General direnv tips

- [Changing where direnv stores its cache](https://github.com/direnv/direnv/wiki/Customizing-cache-location)
- [Quickly setting up direnv in a new nix project](https://github.com/nix-community/nix-direnv/wiki/Shell-integration)

## Other projects in the field

- [lorri](https://github.com/nix-community/lorri)
- [sorri](https://github.com/nmattia/sorri)
- [nixify](https://github.com/kalbasit/nur-packages/blob/master/pkgs/nixify/envrc)
- [lorelei](https://github.com/shajra/direnv-nix-lorelei)
