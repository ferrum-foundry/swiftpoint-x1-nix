# Maintaining the binary package

Swiftpoint supplies pre-built proprietary archives rather than source code.
Package maintenance therefore revolves around inspecting each upstream archive,
adapting its runtime environment, and validating both release channels.

## When a new release fails to build

Start by comparing the new archive layout with the previous working release.
`packages/package.nix` currently expects:

- `Swiftpoint X1 Control Panel` and its licence file;
- `lib/`, `fw/`, `profiles/`, and `translations/`;
- `qt.conf` and `Starter Mappings.spcf`;
- `60-Swiftpoint.rules`; and
- selected Qt plugin directories when present.

If an expected path moved or disappeared, determine whether it was renamed,
made optional, or incorporated into the executable before changing the install
phase. Keep conditional copies for genuinely optional plugin directories, but
allow required application data to fail loudly.

## ELF and library failures

Use the package build log to distinguish three classes of dependency:

1. System libraries should normally come from Nixpkgs through `buildInputs` or
   `runtimeDependencies` and be resolved by `autoPatchelfHook`.
2. Upstream-private or version-coupled libraries may need to remain under
   `$out/share/swiftpoint/lib` and on the wrapped runtime library path.
3. Qt platform and integration plugins must be copied only when needed and made
   discoverable through the Qt wrapper environment.

After changing dependencies or copied plugins, build both channels. Stable and
beta can contain different bundled-library or plugin layouts even when they use
the same shared derivation.

Useful inspection tools include:

```console
file "Swiftpoint X1 Control Panel"
patchelf --print-needed "Swiftpoint X1 Control Panel"
readelf -d "Swiftpoint X1 Control Panel"
find plugins -maxdepth 2 -type f
```

Run those against an unpacked upstream archive, not files copied into the Git
repository.

## Udev rules

Each archive's `60-Swiftpoint.rules` remains release-specific even when two
versions currently contain identical bytes. For a new release:

1. compare the rule with both current channels;
2. review changed USB/HID identifiers, modes, groups, tags, or invoked tools;
3. confirm the derivation still installs it under `lib/udev/rules.d`; and
4. verify the NixOS module still registers the selected package through
   `services.udev.packages`.

Do not replace upstream rules with one shared copy merely because the current
files match. A later application release may depend on new device access.

## Runtime testing

A successful ELF build establishes that the binary can be patched, not that all
device and GUI behavior works. When practical, test:

- launch under the desktop session types relevant to the change;
- mouse and receiver detection after reconnecting them;
- reading and writing a fresh profile;
- preservation of existing profiles and unrelated settings;
- the desktop entry; and
- stable/beta channel behavior without installing both simultaneously.

Treat firmware flashing separately from package validation. A declarative
application rollback does not roll back firmware already written to a device.
