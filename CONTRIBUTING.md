# Contributing

## Updating releases

Run the updater from the repository root:

```sh
./update.sh
```

One invocation discovers both current upstream channels, adds any missing
release manifests, and advances the stable and beta pointers independently.
Existing historical manifests remain available as versioned flake outputs.

To add a release listed on the upstream page without changing either current
pointer:

```sh
./update.sh --add VERSION
```

Review all generated metadata, including firmware versions, before committing.
Then format and validate the flake:

```sh
nix fmt
nix flake check
nix build .#stable
nix build .#beta
```

## Package layout

- `packages/package.nix` contains the shared derivation.
- `packages/default.nix` discovers manifests and selects current channels.
- `packages/releases/` contains immutable release metadata.
- `modules/default.nix` provides the NixOS integration.

Each application archive retains its own upstream udev rules. This allows a
future release to change device support without requiring a separate packaging
update for shared rules.

## Automated updates

The `Update Swiftpoint releases` GitHub Actions workflow runs every day and can
also be started manually from the Actions tab. When `./update.sh` changes
release metadata, the workflow validates the flake, builds both current
channels, and opens or updates a pull request from
`automated/update-swiftpoint-releases`.

The repository must allow GitHub Actions to create pull requests. Keep update
pull requests subject to normal review: the workflow downloads and hashes new
proprietary upstream binaries, but does not independently establish their
trustworthiness or firmware safety.
