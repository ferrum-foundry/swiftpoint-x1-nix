# Per-user settings

The Swiftpoint X1 Control Panel stores its settings in:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/Swiftpoint X1 Control Panel/settings.ini
```

Before each launch, the package wrapper ensures that these settings exist in the `[General]` section:

```ini
AutoUpdate=false
ReleaseChannel=Stable
```

The beta package writes `ReleaseChannel=Beta` instead. All other settings are preserved.

## Why the wrapper does this

The upstream software updater cannot replace an application stored in the immutable Nix store. Application upgrades must instead be performed by updating the flake input and rebuilding the system.

The application also persists one release channel per user. Without correcting that value, the beta package can inherit `Stable` and offer an older stable application as an apparent update.

Because the wrapper runs on every launch, manually changing either value in `settings.ini` does not persist after the packaged application is started.

## Releases supporting upstream update policy

A release manifest can declare `features.disableUpdatesPolicy = true` after upstream support has been verified. For that release, the wrapper sets `SWIFTPOINT_X1_DISABLE_UPDATES=1` and does not create or edit `settings.ini`, including `ReleaseChannel`. Upstream removes update/channel controls when this policy is active.

Existing manifests default to `false` and retain the workaround above. No currently packaged release is marked as supporting the policy. Do not enable it solely because a version number is newer; confirm support first.

For a verified backport or custom release, the package argument is overridable:

```nix
package.override { supportsUpdatePolicy = true; }
```

This capability concerns application software updates only, not mouse or receiver firmware updates.
