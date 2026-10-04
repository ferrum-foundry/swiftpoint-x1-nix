# Firmware considerations

The package does not modify, intercept, or independently validate the application's firmware-update process.

Application packages can be changed or rolled back declaratively, but that does not roll back firmware already written to a physical device. Upstream does not document every cross-version or downgrade combination, so this packaging does not claim that arbitrary firmware downgrades are safe or supported.

Before changing between stable and beta firmware:

- export or otherwise back up important mouse profiles;
- follow Swiftpoint's guidance when matching application and firmware versions; and
- consult Swiftpoint support when a downgrade or recovery operation is needed.
