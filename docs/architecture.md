# Package and release architecture

## Separation of package construction and release selection

`packages/package.nix` describes how one Swiftpoint release becomes a Nix derivation. Its `stdenv.mkDerivation` call patches and installs the upstream archive, adds the desktop entry and release-specific udev rules, and wraps the executable.

That file deliberately does not decide which version is current. It receives a `release` value containing the version, channel, archive URL, and hash. The channel is derived from the manifest directory rather than stored inside the manifest.

`packages/default.nix` handles release selection instead. It:

1. imports every manifest under `packages/releases/stable/` and `packages/releases/beta/`;
1. calls `package.nix` once for each manifest;
1. exposes the resulting derivations through the nested `releases.CHANNEL.VERSION` set; and
1. points `stable`, `beta`, and `default` at the selected versions.

This keeps prior versions available while allowing the stable and beta pointers to advance independently. Channel and version form the release identity, so both channels can legitimately publish the same version string without colliding.

## Release manifests

Each `packages/releases/CHANNEL/VERSION.nix` file is immutable metadata for one upstream release:

```nix
{
  version = "3.1.3.1";
  source = {
    url = "...";
    hash = "sha256-...";
  };
}
```

The parent directory supplies `channel`. Keeping that dimension in the path prevents a stable and beta release with the same version from sharing one manifest accidentally.

The upstream archive remains the source of the executable, bundled libraries, profiles, translations, firmware images, and udev rules. These large binary artifacts are not vendored into this repository.

## Updating is explicit

A new upstream release does not automatically change a checked-out or locked flake. Running `./update.sh` discovers the currently advertised stable and beta versions, adds missing manifests, and updates both channel pointers. Users then receive those changes only after updating their flake input and rebuilding.

The updater intentionally handles both channels in one normal invocation. Prior stable-release discovery is kept in `update-prior.sh VERSION` because it depends on scraping the upstream KB page; it writes under the stable channel without moving either current pointer. The page does not provide a corresponding beta archive, so prior beta manifests come only from beta feed versions previously captured by the normal updater. See `CONTRIBUTING.md` for the maintainer workflow.

The flake exposes only the current `default`, `stable`, and `beta` package outputs. The overlay exposes retained releases as `pkgs.swiftpoint-x1-control-panel-releases.CHANNEL.VERSION` for manual installation.

## Why udev rules remain release-specific

The currently packaged stable and beta archives contain byte-identical `60-Swiftpoint.rules` files. They remain inside each application derivation so future upstream releases can change supported hardware or permissions together with the matching application release.
