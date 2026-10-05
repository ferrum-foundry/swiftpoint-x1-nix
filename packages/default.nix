{
  lib,
  callPackage,
  releasesDirectory ? ./releases,
}:

let
  currentStableVersion = "3.1.3.1";
  currentBetaVersion = "3.1.3.39";
  channels = [
    "stable"
    "beta"
  ];

  releaseMetadata = lib.genAttrs channels (
    channel:
    let
      releaseDirectory = releasesDirectory + "/${channel}";
      releaseFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
        builtins.readDir releaseDirectory
      );
    in
    lib.mapAttrs' (
      filename: _:
      let
        release = import (releaseDirectory + "/${filename}");
      in
      lib.nameValuePair release.version (release // { inherit channel; })
    ) releaseFiles
  );

  releases = lib.mapAttrs (
    _: releases:
    lib.mapAttrs (
      _: release:
      callPackage ./package.nix {
        inherit release;
      }
    ) releases
  ) releaseMetadata;
in
{
  inherit
    currentStableVersion
    currentBetaVersion
    releases
    ;
  stable = releases.stable.${currentStableVersion};
  beta = releases.beta.${currentBetaVersion};
  default = releases.stable.${currentStableVersion};
}
