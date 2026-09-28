# Troubleshooting

## “Save Failed — Check connection and press Enter to retry”

During testing, the connection was working, but there was a problem in the profile data the application was trying to write to the mouse. Updating the receiver firmware did not resolve it. Resetting to a new profile allowed the write to succeed.

When the error occurs while saving a profile:

1. export or back up any important profile;
1. create or reset to a fresh profile;
1. verify that the fresh profile can be written to the mouse; and
1. recreate or selectively import settings from the failing profile.

Only if a fresh profile also fails should the connection, device permissions, udev rules, and receiver/mouse firmware pairing become the next suspects.

## Application access to the mouse or receiver

When using the NixOS module, rebuild the system and reconnect the affected device so udev reapplies its rules. Direct package users must put the same selected package in both `environment.systemPackages` and `services.udev.packages`.

Do not run the graphical application as root as a substitute for installing the device-access rules.

## An older release is offered as a software update

The application persists its release channel per user. The packaged wrapper sets the channel to match the selected package and disables the in-application software updater on every launch. See [Per-user settings](per-user-settings.md) for the settings and their location.
