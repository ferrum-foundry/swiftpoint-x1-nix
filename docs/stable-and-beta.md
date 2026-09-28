# Stable and beta coexistence

Do not install the stable and beta packages simultaneously in one NixOS
configuration.

Both packages expose the same executable, desktop entry, and udev-rule paths.
NixOS constructs `environment.systemPackages` with collisions ignored, so the
first package in the list supplies the visible executable rather than the
configuration failing clearly.

The udev module copies rules in package order. A later
`60-Swiftpoint.rules` replaces an earlier file with the same name. The stable
and beta rules are currently identical, but that is not guaranteed for future
releases.

Both applications also use the same per-user configuration and physical-device
state. Launching one channel after the other changes the persisted release
channel used by the application.

Use the NixOS module's single channel option:

```nix
programs.swiftpoint-x1-control-panel.channel = "stable";
```

The module rejects a configuration containing both of this flake's stable and
beta derivations in `environment.systemPackages` or `services.udev.packages`.
Nix itself still permits both derivations to exist in the Nix store, as it does
for different versions of any package.
