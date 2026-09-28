# Comparison with NiX1-Control-Panel

This flake and [Blu3SoulsIT/NiX1-Control-Panel](https://github.com/Blu3SoulsIT/NiX1-Control-Panel) package the same proprietary Linux application. This comparison reflects the alternative flake as reviewed on 28 September 2026, when it packaged beta version `3.0.7.20`.

| Area | This flake | NiX1-Control-Panel |
| --- | --- | --- |
| Releases | Stable, beta and versioned outputs backed by release manifests | One hard-coded beta release |
| Updates | Updater plus a daily/manual pull-request workflow | Manual source edits |
| Integration | Packages, overlay and NixOS module | Package flake |
| Stable/beta safety | Module selects one channel and detects conflicting installations | Not modelled |
| Runtime policy | Disables self-updates and sets the package's release channel on launch | No equivalent wrapper |
| Udev | Rules installed automatically by the NixOS module | Rules require manual NixOS configuration |
| Dependencies | Current Qt 6 release with bundled OpenSSL 3 libraries | Qt 5 and OpenSSL 1.1 from an older nixpkgs revision |
| Installed payload | Explicit allow-list of runtime files | Nearly the complete upstream archive |
| Desktop icon | Swiftpoint icon recovered from the older official archive | Installs that archive's bundled Swiftpoint icon |
| Metadata | Correctly marked as unfree native binary code | Was marked free/redistributable when reviewed |
| Validation | Automated package, module, wrapper and evaluation checks | No equivalent checks found |

The alternative flake is a compact package for one release. This flake is designed as an ongoing distribution interface with multiple channels, automated updates, NixOS integration and tests.

## Useful differences

One idea from the alternative remains worth considering here:

1. Preserve the complete upstream payload, or test that the allow-list has not omitted newly added runtime files.

The alternative flake revealed that Swiftpoint's `3.0.7.20` archive included `profiles/Desktop/logo.png`. Neither current release contains that file—or any other image asset—so this flake retains a copy from the older official archive at `assets/logo.png` and installs it as the desktop icon. Ideally each release would supply its own icon so visual changes could follow the packaged version.
