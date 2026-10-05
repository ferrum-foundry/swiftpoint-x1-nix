# Swiftpoint X1 Control Panel for NixOS

Nix packaging for the Linux version of the Swiftpoint X1 Control Panel, with stable and beta release channels and the device-access rules required by the application.

See the [Swiftpoint website](https://www.swiftpoint.com/), the [X1 Control Panel download page](https://support.swiftpoint.com/portal/en/kb/articles/swiftpoint-x1-control-panel-download), and Swiftpoint's [experimental Linux release page](https://support.swiftpoint.com/portal/en/kb/articles/x1-control-panel-linux) for upstream information and manual downloads.

The upstream application is proprietary software. You must allow unfree packages in your Nixpkgs configuration.

## NixOS module

Add the input and NixOS module to your `flake.nix`:

```nix
{
  # 1. Import the flake
  inputs.swiftpoint-x1.url = "github:ferrum-foundry/swiftpoint-x1-nix";
  inputs.swiftpoint-x1.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
      swiftpoint-x1,
    }:
    {
      nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          # 2. Include the module
          swiftpoint-x1.nixosModules.default
        ];
      };
    };
}
```

Enable the application in your NixOS configuration:

```nix
{
  nixpkgs.config.allowUnfree = true;

  programs.swiftpoint-x1-control-panel = {
    enable = true;
    channel = "stable"; # or "beta"
  };
}
```

The module installs the application and its udev rules. Rebuild NixOS, then reconnect the mouse and receiver if the application cannot initially access them.

## Direct package installation

Run a package without installing it:

```console
nix run github:ferrum-foundry/swiftpoint-x1-nix
nix run github:ferrum-foundry/swiftpoint-x1-nix#beta
```

`nix run` does not install udev rules. Device access requires `60-Swiftpoint.rules` to be configured system-wide; the NixOS module does this automatically.

The package outputs are `default`, `stable`, and `beta`. When adding one directly to `environment.systemPackages`, also add the same package to `services.udev.packages`.

## Overlay

You can use the packages directly instead of enabling the module-managed application.

Stable:

```nix
environment.systemPackages = [ pkgs.swiftpoint-x1-control-panel ];
services.udev.packages = [ pkgs.swiftpoint-x1-control-panel ];
```

Beta:

```nix
environment.systemPackages = [ pkgs.swiftpoint-x1-control-panel-beta ];
services.udev.packages = [ pkgs.swiftpoint-x1-control-panel-beta ];
```

Specific stable release:

```nix
environment.systemPackages = [ pkgs.swiftpoint-x1-control-panel-releases.stable."3.1.3.1" ];
services.udev.packages = [ pkgs.swiftpoint-x1-control-panel-releases.stable."3.1.3.1" ];
```

Specific beta release:

```nix
environment.systemPackages = [ pkgs.swiftpoint-x1-control-panel-releases.beta."3.1.3.39" ];
services.udev.packages = [ pkgs.swiftpoint-x1-control-panel-releases.beta."3.1.3.39" ];
```

See [docs](docs/) for packaging behavior and known caveats.
