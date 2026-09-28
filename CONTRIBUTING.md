# Contributing

## Updating releases

Run the updater from the repository root:

```sh
./update.sh
```

One invocation discovers both current upstream channels, adds any missing release manifests, and advances the stable and beta pointers independently. Existing historical manifests remain available as versioned flake outputs.

To add a release listed on the upstream page without changing either current pointer:

```sh
./update.sh --add VERSION
```

Review all generated metadata, including firmware versions, before committing. Then format and validate the flake:

```sh
nix fmt .
nix flake check
nix build .#stable
nix build .#beta
```

An update pull request should confirm that:

- stable and beta versions match Swiftpoint's published release pages;
- archive URLs point to the intended platform and channel;
- hashes were produced from those exact archives;
- recorded mouse and receiver firmware versions match the release notes;
- any archive-layout, bundled-library, plugin, or udev-rule changes were reviewed; and
- both current packages build successfully.

Running the updater against an unchanged upstream state should not change `packages/default.nix` or `packages/releases/`.

## Package layout

- `packages/package.nix` contains the shared derivation.
- `packages/default.nix` discovers manifests and selects current channels.
- `packages/releases/` contains immutable release metadata.
- `modules/default.nix` provides the NixOS integration.

Each application archive retains its own upstream udev rules. This allows a future release to change device support without requiring a separate packaging update for shared rules.

## Automated updates

The `Update Swiftpoint releases` GitHub Actions workflow runs every day and can also be started manually from the Actions tab. When `./update.sh` changes release metadata, the workflow validates the flake, builds both current channels, and opens or updates a pull request from `automated/update-swiftpoint-releases`.

The repository must allow GitHub Actions to create pull requests. Keep update pull requests subject to normal review: the workflow downloads and hashes new proprietary upstream binaries, but does not independently establish their trustworthiness or firmware safety.

When changing the workflow, validate it with:

```sh
nix run nixpkgs#actionlint -- .github/workflows/*.yml
```

Review the workflow's permissions, concurrency behavior, checkout ref, pull request base, no-change path, and runner environment. In particular, `update.sh` uses a `nix-shell` shebang and requires `<nixpkgs>` through `NIX_PATH`.

## Validation checklist

Before handing off a package or module change:

1. Check `git status` and separate unrelated work from the intended change.
1. Run `nix fmt .`.
1. Run `nix flake check`.
1. Run `git diff --check`.
1. Review both staged and unstaged diffs.
1. Confirm generated `result` links and temporary files are not included.

The flake checks build both current channels and exercise the NixOS module, settings wrapper, conflict assertion, package overrides, and Darwin-safe overlay behavior. See [Testing and validation](docs/development/testing.md) for the purpose and expected behavior of each check.

## Binary package changes

When upstream changes its archive layout, ELF dependencies, Qt plugins, or udev rules, follow [Maintaining the binary package](docs/development/binary-packaging.md). Do not vendor the unpacked upstream application into the repository.

## Documentation checklist

When behavior or packaging decisions change:

- update the rationale as well as the resulting behavior;
- distinguish confirmed behavior from observations and unresolved causes;
- keep installation instructions in `README.md` and maintainer procedures here or under `docs/development/`;
- add new documentation pages to `docs/README.md`; and
- check that code changes have not invalidated existing troubleshooting or platform guidance.
