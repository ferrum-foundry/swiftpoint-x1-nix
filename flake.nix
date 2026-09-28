{
  description = "Nix packaging for the Swiftpoint X1 Control Panel";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs {
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
        // swiftpointPackages.versions
      );

      overlays.default = final: _prev:
        let
          swiftpointPackages = final.callPackage ./packages { };
        in
        {
          swiftpoint-x1-control-panel = swiftpointPackages.stable;
          swiftpoint-x1-control-panel-beta = swiftpointPackages.beta;
          swiftpointX1Versions = swiftpointPackages.versions;
        };

      nixosModules.default = import ./modules { inherit self; };
      nixosModules.swiftpoint-x1-control-panel = self.nixosModules.default;

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
