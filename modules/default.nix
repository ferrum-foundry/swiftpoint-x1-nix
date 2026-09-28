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
  contains = package: lib.any (candidate: toString candidate == toString package) configuredPackages;
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
        assertion = !(contains packages.stable && contains packages.beta);
        message = ''
          The stable and beta Swiftpoint X1 Control Panel packages cannot be
          installed simultaneously. Remove one of them or select a single
          programs.swiftpoint-x1-control-panel.channel value.
        '';
      }
    ];

    environment.systemPackages = lib.mkIf cfg.enable [ selectedPackage ];
    services.udev.packages = lib.mkIf cfg.enable [ selectedPackage ];
  };
}
