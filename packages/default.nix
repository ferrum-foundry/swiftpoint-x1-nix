{ lib, callPackage }:

let
  currentStableVersion = "3.1.3.1";
  currentBetaVersion = "3.1.3.39";

  releaseFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
    builtins.readDir ./releases
  );

  releases = lib.mapAttrs' (
    filename: _:
    let
      release = import (./releases + "/${filename}");
    in
    lib.nameValuePair release.version release
  ) releaseFiles;

  versions = lib.mapAttrs (
    _: release:
    callPackage ./package.nix {
      inherit release;
    }
  ) releases;
in
{
  inherit currentStableVersion currentBetaVersion versions;
  stable = versions.${currentStableVersion};
  beta = versions.${currentBetaVersion};
  default = versions.${currentStableVersion};
}
