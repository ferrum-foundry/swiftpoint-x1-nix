# Stable and beta coexistence

Do not install the stable and beta packages simultaneously in one NixOS configuration.

Both packages expose the same executable, desktop entry, and udev-rule paths. NixOS constructs `environment.systemPackages` with collisions ignored, so the first package in the list supplies the visible executable rather than the configuration failing clearly.

The udev module copies rules in package order. A later `60-Swiftpoint.rules` replaces an earlier file with the same name. The stable and beta rules are currently identical, but that is not guaranteed for future releases.

Both applications also use the same per-user configuration and physical-device state. Launching one channel after the other changes the persisted release channel used by the application.

Use the NixOS module's single channel option:

```nix
programs.swiftpoint-x1-control-panel.channel = "stable";
```

Package derivations carry a family marker and release-channel value. The module uses those values to reject a configuration containing different Swiftpoint releases in `environment.systemPackages` or `services.udev.packages`. This also works for normal package overrides rather than relying on exact store-path identity. Nix itself still permits both derivations to exist in the Nix store, as it does for different versions of any package.

## Why the packages or overlay cannot enforce this alone

A derivation describes how to build one package. It cannot inspect the other packages that a user will later place in a profile or NixOS configuration. Nix also deliberately allows multiple versions of software to coexist in the store, and it has no Debian/RPM-style package-conflict declaration for this purpose.

An overlay constructs and names packages but likewise cannot see the eventual values of `environment.systemPackages` or `services.udev.packages`. Setting package priority could choose which colliding file wins, but would not reject the invalid combination.

Only NixOS module evaluation has both package definitions and the completed configuration in scope. That is why mutual-exclusion checking belongs in the module assertion while the overlay continues to expose both packages.
