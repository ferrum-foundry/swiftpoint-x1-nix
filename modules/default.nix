{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.swiftpoint-x1-control-panel;
  system = pkgs.stdenv.hostPlatform.system;
  packages = self.packages.${system};
  selectedPackage = packages.${cfg.channel};
  configuredPackages = config.environment.systemPackages ++ config.services.udev.packages;
  swiftpointPackages = lib.filter (
    package: package.swiftpointX1ControlPanel or false
  ) configuredPackages;
  configuredChannels = lib.unique (map (package: package.channel) swiftpointPackages);
in
{
  options.programs.swiftpoint-x1-control-panel = {
    enable = lib.mkEnableOption "Swiftpoint X1 Control Panel";

    channel = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "beta"
      ];
      default = "stable";
      description = "Swiftpoint X1 Control Panel release channel to install.";
    };
  };

  config = {
    assertions = [
      {
        assertion = builtins.length configuredChannels <= 1;
        message = ''
          Different Swiftpoint X1 Control Panel releases cannot be installed
          simultaneously. Remove the conflicting packages or select a single
          programs.swiftpoint-x1-control-panel.channel value.
        '';
      }
    ];

    environment.systemPackages = lib.mkIf cfg.enable [ selectedPackage ];
    services.udev.packages = lib.mkIf cfg.enable [ selectedPackage ];
  };
}
