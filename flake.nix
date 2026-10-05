{
  description = "Nix packaging for the Swiftpoint X1 Control Panel";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          swiftpointPackages = (pkgsFor system).callPackage ./packages { };
        in
        {
          inherit (swiftpointPackages) stable beta;
          default = swiftpointPackages.stable;
        }
      );

      overlays.default =
        final: prev:
        nixpkgs.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux (
          let
            swiftpointPackages = final.callPackage ./packages { };
          in
          {
            swiftpoint-x1-control-panel = swiftpointPackages.stable;
            swiftpoint-x1-control-panel-beta = swiftpointPackages.beta;
            swiftpoint-x1-control-panel-releases = swiftpointPackages.releases;
          }
        );

      nixosModules.default = import ./modules { inherit self; };
      nixosModules.swiftpoint-x1-control-panel = self.nixosModules.default;

      checks = forAllSystems (
        system:
        import ./tests {
          inherit self nixpkgs system;
          pkgs = pkgsFor system;
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
