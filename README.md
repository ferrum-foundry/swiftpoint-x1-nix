# Swiftpoint X1 Control Panel for NixOS

Nix packaging for the Linux version of the Swiftpoint X1 Control Panel, with
stable and beta release channels and the device-access rules required by the
application.

The upstream application is proprietary software. You must allow unfree
packages in your Nixpkgs configuration.

## NixOS module

Add the flake input:

```nix
{
  inputs.swiftpoint-x1.url = "github:ferrum-foundry/swiftpoint-x1-nix";
}
```

Import the module and select one release channel:

```nix
{
  inputs,
  ...
}:
{
  imports = [ inputs.swiftpoint-x1.nixosModules.default ];

  nixpkgs.config.allowUnfree = true;

  programs.swiftpoint-x1-control-panel = {
    enable = true;
    channel = "stable"; # or "beta"
  };
}
```

The module installs the application and its udev rules. Rebuild NixOS, then
reconnect the mouse and receiver if the application cannot initially access
them.

## Direct package installation

Run a package without installing it:

```console
nix run github:ferrum-foundry/swiftpoint-x1-nix
nix run github:ferrum-foundry/swiftpoint-x1-nix#beta
```

The available package outputs are `default`, `stable`, and `beta`. When adding
one directly to `environment.systemPackages`, also add the same package to
`services.udev.packages`.

## Overlay

The default overlay provides:

```nix
pkgs.swiftpoint-x1-control-panel
pkgs.swiftpoint-x1-control-panel-beta
pkgs.swiftpointX1Versions
```

See [docs](docs/) for packaging behavior and known caveats.
