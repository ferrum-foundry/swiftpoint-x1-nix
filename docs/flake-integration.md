# Flake integration and platform support

## Why `flake.lock` is committed

This repository is both a package flake and a NixOS module. Its checked-in `flake.lock` gives direct builds, local development, and CI a known Nixpkgs revision. Without it, unrelated changes in a moving Nixpkgs branch could alter or break the package between otherwise identical runs.

Consumers are encouraged to make this flake follow the Nixpkgs input already used by their system:

```nix
inputs.swiftpoint-x1.inputs.nixpkgs.follows = "nixpkgs";
```

With that declaration, the consumer's top-level lock file supplies the Nixpkgs revision. This avoids a second Nixpkgs source and evaluation while allowing this repository to keep a reproducible revision for standalone use.

The trade-off is intentional: a consumer using `follows` evaluates this package against their Nixpkgs revision rather than the revision tested by this repository. Compatibility should therefore be checked periodically against updated Nixpkgs revisions.

## Current Linux-only package outputs

The package outputs currently implemented by this flake use Swiftpoint's x86-64 Linux binary, so they are exposed only for `x86_64-linux`.

Adding the flake as an input on another platform is harmless because inputs do nothing until an output is used. The overlay is also designed to be safe in a shared Linux/Darwin configuration: it contributes Swiftpoint package attributes only when `prev.stdenv.hostPlatform.isLinux` is true.

The platform check uses `prev`, not `final`. Consulting `final.stdenv` while deciding which attributes the overlay contributes introduces an overlay fixpoint dependency and can cause infinite recursion.

The NixOS module must not be imported into nix-darwin. It uses NixOS-specific options, including `services.udev.packages`.

Swiftpoint also publishes a fully supported macOS application as a universal `.pkg` for Apple Silicon and Intel Macs. Native nix-darwin support is therefore feasible and tracked separately. It needs a macOS-specific derivation and Darwin module because the application bundle, installer format, device access, and integration points differ from the experimental Linux archive. It cannot be implemented by enabling the existing Linux derivation on Darwin.

## Flake outputs

The public package outputs are:

- `packages.x86_64-linux.default`, which follows stable;
- `packages.x86_64-linux.stable`;
- `packages.x86_64-linux.beta`.

The overlay exposes the current stable and beta packages plus `swiftpoint-x1-control-panel-releases.CHANNEL.VERSION` for selecting a specific retained release. The NixOS module uses the current flake package outputs directly and adds the selected derivation to both `environment.systemPackages` and `services.udev.packages`.
