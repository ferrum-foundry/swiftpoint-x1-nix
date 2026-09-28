# Packaging workarounds

Swiftpoint distributes the Linux X1 Control Panel as an experimental,
pre-built application rather than a native Nix package. The package applies
the following compatibility and lifecycle workarounds.

## Patch proprietary Linux binaries for NixOS

`autoPatchelfHook` resolves the pre-built ELF binaries against Nix store
libraries. `wrapQtAppsHook` supplies the Qt runtime environment, while bundled
libraries and selected plugins remain available through the package's runtime
library path.

## Install release-specific device-access rules

Each package installs Swiftpoint's `60-Swiftpoint.rules` from that release's
archive. The NixOS module registers the selected package through
`services.udev.packages`, allowing the application to access supported mouse
and receiver HID nodes without running as root.

Keeping the rule with its release preserves any future upstream changes to
supported hardware or permissions.

## Configure software updates and release channels

The executable wrapper applies two settings before each launch. It disables an
updater that cannot replace software in the immutable Nix store, and it matches
the saved release channel to the package being launched. See
[Per-user settings](per-user-settings.md) for the exact behavior.
