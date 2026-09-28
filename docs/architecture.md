# Package and release architecture

## Separation of package construction and release selection

`packages/package.nix` describes how one Swiftpoint release becomes a Nix
derivation. Its `stdenv.mkDerivation` call patches and installs the upstream
archive, adds the desktop entry and release-specific udev rules, and wraps the
executable.

That file deliberately does not decide which version is current. It receives a
`release` value containing the version, channel, archive URL, hash, and known
firmware versions.

`packages/default.nix` handles release selection instead. It:

1. imports every manifest under `packages/releases/`;
2. calls `package.nix` once for each manifest;
3. exposes the resulting derivations through `versions`; and
4. points `stable`, `beta`, and `default` at the selected versions.

Consequently, `packages/default.nix` returns an attribute set of packages, not
a derivation itself. The `stable`, `beta`, and versioned members of that set are
the derivations created by `stdenv.mkDerivation`.

This keeps historical versions available while allowing the stable and beta
pointers to advance independently.

## Release manifests

Each `packages/releases/VERSION.nix` file is immutable metadata for one
upstream release:

```nix
{
  version = "3.1.3.1";
  channel = "stable";
  source = {
    url = "...";
    hash = "sha256-...";
  };
  firmware = {
    z3 = 99;
    receiver = 99;
  };
}
```

The upstream archive remains the source of the executable, bundled libraries,
profiles, translations, firmware images, and udev rules. These large binary
artifacts are not vendored into this repository.

Firmware metadata is recorded for review and compatibility context; it does
not control firmware flashing.

## Updating is explicit

A new upstream release does not automatically change a checked-out or locked
flake. Running `./update.sh` discovers the currently advertised stable and beta
versions, adds missing manifests, and updates both channel pointers. Users then
receive those changes only after updating their flake input and rebuilding.

The updater intentionally handles both channels in one normal invocation. The
`--add VERSION` form exists only to preserve a listed historical release
without moving either current pointer. See `CONTRIBUTING.md` for the maintainer
workflow.

## Why udev rules remain release-specific

The currently packaged stable and beta archives contain byte-identical
`60-Swiftpoint.rules` files. They remain inside each application derivation so
future upstream releases can change supported hardware or permissions together
with the matching application release.
