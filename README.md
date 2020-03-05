# nix-direnv

A fast, persistent use_nix implementation for direnv.
Prominent features:

- significantly faster after the first run by caching the nix-shell environment
- prevents garbage collection of build dependencies by symlinking the resulting
  shell derivation in the user's `gcroots` (Life is too short to loose your
  build cache of your project if you are in a plane without internet connection)

## USAGE

```console
$ git clone https://github.com/nix-community/nix-direnv $HOME/.nix-direnv
```

Then source the direnvrc from this repository in your own `.direnvrc`

```bash
# put this in ~/.direnvrc
source $HOME/.nix-direnv/direnvrc
```

For derivations to persist garbage collection, set the following in nix.conf:

```
keep-derivations = true
keep-outputs = true
```
