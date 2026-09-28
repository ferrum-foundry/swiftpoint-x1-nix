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
