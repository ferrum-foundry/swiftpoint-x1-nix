# Suggested XDG directory layout for Swiftpoint X1 Control Panel

## Summary

The Linux version of Swiftpoint X1 Control Panel currently stores all of its per-user files under:

```text
$XDG_CONFIG_HOME/Swiftpoint X1 Control Panel/
```

Using `$XDG_CONFIG_HOME` for application preferences and mouse profiles is reasonable. However, the same directory also contains logs, downloaded application updates, and temporary firmware images. Those files have different lifecycle and backup requirements and would be better placed in the corresponding XDG state and cache directories.

This document is a suggested refinement for possible consideration by the Swiftpoint team. The current layout does not prevent the application from functioning.

## Current layout

```text
$XDG_CONFIG_HOME/Swiftpoint X1 Control Panel/
├── settings.ini
├── autosave.spcf
├── Starter Mappings.spcf
├── log.txt
├── Driver Updates/
│   └── VERSION.tar.xz
└── TempFW/
    ├── Z3Mouse.hex
    └── Z3Dongle.hex
```

This combines configuration, application state, and disposable downloads in a single configuration directory.

## Recommended classification

| Item | Suggested category | Rationale |
| --- | --- | --- |
| `settings.ini` | Configuration | Controls application preferences and behaviour. |
| Mouse profiles and mappings | Configuration | Define how the mouse behaves. |
| `autosave.spcf` | State | Represents recoverable current application or device state. |
| `log.txt` | State | Logs are within the intended scope of `$XDG_STATE_HOME`. |
| `Driver Updates/` | Cache | Downloaded installers can be fetched again. |
| `TempFW/` | Cache | Extracted firmware payloads are temporary and reproducible. |
| Explicitly exported profiles | User data | User-selected exports belong in a visible, user-selected location. |

Profiles are the least clear-cut category. A profile may be valuable portable user data, but profiles configuring button mappings, DPI, lighting, and device behaviour also fit naturally under `$XDG_CONFIG_HOME`. Explicit exports are better treated as user data and saved to a location chosen by the user.

## Suggested layout

```text
$XDG_CONFIG_HOME/swiftpoint-x1/
├── settings.ini
├── profiles/
└── Starter Mappings.spcf

$XDG_STATE_HOME/swiftpoint-x1/
├── autosave.spcf
└── log.txt

$XDG_CACHE_HOME/swiftpoint-x1/
├── driver-updates/
└── firmware/
```

When the corresponding variables are unset, the XDG defaults are:

```text
$XDG_CONFIG_HOME = ~/.config
$XDG_STATE_HOME  = ~/.local/state
$XDG_CACHE_HOME  = ~/.cache
```

The directory name does not need to change for XDG compliance, but `Swiftpoint X1 Control Panel` is atypical for a Linux application directory because it contains uppercase letters and spaces. A lowercase, space-free application ID such as `swiftpoint-x1` would be more conventional and easier to use from shells and packaging tools. Retaining the existing name would reduce migration work and preserve compatibility, so a rename should use the same backwards-compatible migration strategy as any directory-layout change.

## Benefits

- Backup tools can include settings and profiles without archiving reproducible application downloads.
- Cache-cleaning tools can safely remove update archives and temporary firmware.
- Logs and autosave state no longer appear to be durable preferences.
- Users can reset application state or clear caches without losing profiles.
- Packaging and sandboxing systems can assign more accurate permissions and persistence policies to each class of file.

## Backwards-compatible migration

1. Continue reading configuration and profiles from the existing directory.
1. Move logs and autosave state only when the destination does not exist.
1. Move or discard downloaded installers and temporary firmware under the cache directory.
1. Preserve explicit profile exports in their user-selected locations.
1. Record migration completion so interrupted migrations can resume safely.
1. For at least one release cycle, fall back to old locations when a file is absent from its new location.

Alternatively, new installations could use the revised layout while existing installations retain the legacy layout until an explicit migration is offered.

The category definitions and default paths come from the [XDG Base Directory Specification, version 0.8](https://specifications.freedesktop.org/basedir/0.8/).
