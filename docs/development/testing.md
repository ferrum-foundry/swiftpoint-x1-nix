# Testing and validation

## Routine validation

Run the formatter and the complete check set from the repository root:

```console
nix fmt .
nix flake check
```

`nix flake check` is the main regression-test entry point. It:

- builds the current stable and beta packages;
- verifies that each module channel adds the matching package to both `environment.systemPackages` and `services.udev.packages`;
- verifies that conflicting channels are rejected even when one derivation has been overridden;
- runs the stable and beta settings helpers in an isolated XDG directory;
- checks that managed settings are updated without losing unrelated settings;
- runs a helper twice to check that it does not create duplicate keys; and
- evaluates the overlay against an Apple Silicon Darwin package set and checks that it does not expose the Linux packages.

The package builds are also available individually when investigating one channel:

```console
nix build .#stable
nix build .#beta
```

Use `--no-link` when only the build result matters and a `result` symlink would be noise:

```console
nix build .#stable .#beta --no-link
```

## Why the checks exist

### Module checks

A successful module evaluation is not enough. The tests verify both package lists because the application can be present in the system environment while still lacking the udev rules required to access the device.

The conflict test uses an overridden stable derivation rather than comparing only the pristine flake outputs. This guards the package-family marker used by the module and prevents a store-path-only implementation from returning.

### Settings-wrapper checks

Do not launch the graphical application to test settings changes. The package exposes its generated settings helper through `passthru`, allowing the check to run it against a temporary `XDG_CONFIG_HOME`.

The seeded file contains incorrect managed values and an unrelated value. A valid test must show that:

- stable writes `ReleaseChannel=Stable`;
- beta writes `ReleaseChannel=Beta`;
- both write `AutoUpdate=false`;
- unrelated settings survive; and
- repeated launches do not duplicate managed keys.

### Darwin overlay check

The Linux overlay is evaluated against `aarch64-darwin` because shared system flakes commonly install the same overlay on NixOS and nix-darwin hosts. The platform condition must consult `prev.stdenv`, not `final.stdenv`; using `final` there introduces an overlay fixpoint and can cause infinite recursion.

This check only verifies that the current Linux package overlay is harmless on Darwin. It is not a substitute for the planned native macOS package.

## Release-updater validation

The current-release updater accesses Swiftpoint's live JSON feeds. Test it explicitly when changing its parser:

```console
./update.sh
git diff -- packages/default.nix packages/releases
```

When upstream has not changed, the updater should report the current stable and beta versions without changing those files. When it has changed, review the generated metadata and build both packages before accepting the update.

Historical archive discovery uses the KB page through `./update-prior.sh VERSION` and has a separate offline fixture check.

## GitHub Actions validation

After changing a workflow, run:

```console
nix run nixpkgs#actionlint -- .github/workflows/*.yml
```

Besides YAML and expression syntax, review the workflow environment itself. Scripts using a `nix-shell` shebang with `<nixpkgs>` require an appropriate `NIX_PATH`; a successful local run does not prove that a fresh GitHub runner has that environment.

For update workflows, also verify the checkout ref, pull-request base branch, permissions, concurrency policy, no-change path, and whether generated pull requests will trigger any expected follow-up workflows.
