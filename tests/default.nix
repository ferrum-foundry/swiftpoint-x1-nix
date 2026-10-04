{
  self,
  nixpkgs,
  system,
  pkgs,
}:

let
  lib = nixpkgs.lib;
  packages = self.packages.${system};

  mkConfiguration =
    channel:
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        self.nixosModules.default
        {
          system.stateVersion = "26.05";
          programs.swiftpoint-x1-control-panel = {
            enable = true;
            inherit channel;
          };
        }
      ];
    };

  stableConfiguration = mkConfiguration "stable";
  betaConfiguration = mkConfiguration "beta";

  packageIsPresent = option: package: builtins.elem (toString package) (map toString option);

  overriddenStable = packages.stable.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      # Ensure this test uses a distinct overridden derivation.
    '';
  });

  conflictingConfiguration = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.default
      {
        system.stateVersion = "26.05";
        environment.systemPackages = [
          overriddenStable
          packages.beta
        ];
      }
    ];
  };

  conflictDetected = lib.any (
    assertion:
    !assertion.assertion
    && lib.hasInfix "Different Swiftpoint X1 Control Panel releases" assertion.message
  ) conflictingConfiguration.config.assertions;

  darwinPackages = import nixpkgs {
    system = "aarch64-darwin";
    overlays = [ self.overlays.default ];
  };
in
{
  updater-feeds =
    pkgs.runCommand "swiftpoint-updater-feed-tests"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.jq
          pkgs.coreutils
          pkgs.diffutils
          pkgs.gnugrep
          pkgs.gnused
        ];
      }
      ''
        bash ${../.}/tests/update-feeds.sh
        touch "$out"
      '';

  updater-prior =
    pkgs.runCommand "swiftpoint-updater-prior-tests"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.jq
          pkgs.coreutils
          pkgs.diffutils
          pkgs.gnugrep
        ];
      }
      ''
        bash ${../.}/tests/update-prior.sh
        touch "$out"
      '';

  package-stable = packages.stable;
  package-beta = packages.beta;

  module =
    assert builtins.hasAttr "swiftpoint-x1-control-panel" stableConfiguration.pkgs;
    assert builtins.hasAttr "swiftpoint-x1-control-panel-beta" stableConfiguration.pkgs;
    assert builtins.hasAttr "swiftpoint-x1-control-panel-versions" stableConfiguration.pkgs;
    assert packageIsPresent stableConfiguration.config.environment.systemPackages packages.stable;
    assert packageIsPresent stableConfiguration.config.services.udev.packages packages.stable;
    assert packageIsPresent betaConfiguration.config.environment.systemPackages packages.beta;
    assert packageIsPresent betaConfiguration.config.services.udev.packages packages.beta;
    assert conflictDetected;
    pkgs.runCommand "swiftpoint-module-tests" { } ''
      touch "$out"
    '';

  wrapper-settings = pkgs.runCommand "swiftpoint-wrapper-settings-tests" { } ''
    export XDG_CONFIG_HOME="$TMPDIR/config"
    settings_dir="$XDG_CONFIG_HOME/Swiftpoint X1 Control Panel"
    settings_file="$settings_dir/settings.ini"

    mkdir -p "$settings_dir"
    printf '[General]\nUnrelatedSetting=keep-me\nReleaseChannel=Beta\nAutoUpdate=true\n' > "$settings_file"

    ${packages.stable.configureUserSettings}
    grep -qx 'UnrelatedSetting=keep-me' "$settings_file"
    grep -qx 'ReleaseChannel=Stable' "$settings_file"
    grep -qx 'AutoUpdate=false' "$settings_file"

    ${packages.stable.configureUserSettings}
    test "$(grep -c '^ReleaseChannel=' "$settings_file")" -eq 1
    test "$(grep -c '^AutoUpdate=' "$settings_file")" -eq 1

    ${packages.beta.configureUserSettings}
    grep -qx 'UnrelatedSetting=keep-me' "$settings_file"
    grep -qx 'ReleaseChannel=Beta' "$settings_file"
    grep -qx 'AutoUpdate=false' "$settings_file"

    touch "$out"
  '';

  wrapper-runtime-path = pkgs.runCommand "swiftpoint-wrapper-runtime-path-test" { } ''
    wrapper=${packages.stable}/bin/.swiftpoint-x1-control-panel-wrapped

    grep -F '${packages.stable}/share/swiftpoint/lib' "$wrapper"
    if grep -F '$out/share/swiftpoint/lib' "$wrapper"; then
      echo 'Qt wrapper contains an unresolved $out reference' >&2
      exit 1
    fi

    touch "$out"
  '';

  desktop-integration = pkgs.runCommand "swiftpoint-desktop-integration-test" { } ''
    desktop_file=${packages.stable}/share/applications/swiftpoint-x1-control-panel.desktop
    installed_icon=${packages.stable}/share/pixmaps/swiftpoint-x1-control-panel.png

    grep -qx 'Icon=swiftpoint-x1-control-panel' "$desktop_file"
    cmp ${../assets/logo.png} "$installed_icon"

    touch "$out"
  '';

  darwin-overlay =
    assert !(builtins.hasAttr "swiftpoint-x1-control-panel" darwinPackages);
    assert !(builtins.hasAttr "swiftpoint-x1-control-panel-beta" darwinPackages);
    pkgs.runCommand "swiftpoint-darwin-overlay-tests" { } ''
      touch "$out"
    '';
}
