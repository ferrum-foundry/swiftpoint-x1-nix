{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  qt6,
  makeWrapper,
  udev,
  glib,
  fontconfig,
  freetype,
  dbus,
  systemd,
  libGL,
  vulkan-loader,
  libX11,
  libXext,
  libXcursor,
  libXrandr,
  libXi,
  libXrender,
  libxcb,
  makeDesktopItem,
  writeShellScript,
  coreutils,
  gnugrep,
  gnused,
  release,
}:

let
  releaseChannel = if release.channel == "beta" then "Beta" else "Stable";
  configureUserSettings = writeShellScript "swiftpoint-configure-user-settings" ''
    set -euo pipefail

    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    config_dir="$config_home/Swiftpoint X1 Control Panel"
    settings_file="$config_dir/settings.ini"

    ${coreutils}/bin/mkdir -p "$config_dir"

    if [[ ! -e "$settings_file" ]]; then
      printf '[General]\n' > "$settings_file"
    fi

    set_general_setting() {
      local key="$1"
      local value="$2"

      if ${gnugrep}/bin/grep -q "^$key=" "$settings_file"; then
        ${gnused}/bin/sed -i "s/^$key=.*/$key=$value/" "$settings_file"
      elif ${gnugrep}/bin/grep -q '^\[General\]$' "$settings_file"; then
        ${gnused}/bin/sed -i "/^\[General\]$/a $key=$value" "$settings_file"
      else
        printf '\n[General]\n%s=%s\n' "$key" "$value" >> "$settings_file"
      fi
    }

    disable_in_application_software_updates() {
      set_general_setting AutoUpdate false
    }

    match_release_channel_to_package() {
      set_general_setting ReleaseChannel ${lib.escapeShellArg releaseChannel}
    }

    disable_in_application_software_updates
    match_release_channel_to_package
  '';
in
stdenv.mkDerivation rec {
  pname = "swiftpoint-x1-control-panel";
  inherit (release) version;

  src = fetchurl release.source;

  strictDeps = true;

  nativeBuildInputs = [
    autoPatchelfHook
    qt6.wrapQtAppsHook
    makeWrapper
  ];

  buildInputs = [
    udev
    glib
    fontconfig
    freetype
    dbus
    systemd
    libGL
    vulkan-loader
    libX11
    libXext
    libXcursor
    libXrandr
    libXi
    libXrender
    libxcb
    qt6.qtbase
    qt6.qtsvg
    qt6.qtwayland
  ];

  runtimeDependencies = [
    udev
    systemd
  ];

  desktopItem = makeDesktopItem {
    name = "swiftpoint-x1-control-panel";
    exec = "swiftpoint-x1-control-panel";
    icon = "swiftpoint-x1-control-panel";
    comment = "Configure and manage Swiftpoint mice settings and profiles";
    desktopName = "Swiftpoint X1 Control Panel";
    genericName = "Mouse Configuration Utility";
    categories = [
      "Settings"
      "HardwareSettings"
      "Utility"
    ];
    terminal = false;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/swiftpoint"

    cp -r lib fw profiles translations qt.conf "Starter Mappings.spcf" "$out/share/swiftpoint/"
    cp "Swiftpoint X1 Control Panel" "$out/share/swiftpoint/"
    cp "Swiftpoint X1 Control Panel Licence.txt" "$out/share/swiftpoint/"

    mkdir -p "$out/share/swiftpoint/plugins"
    if [ -d plugins/platforms ]; then cp -r plugins/platforms "$out/share/swiftpoint/plugins/"; fi
    if [ -d plugins/tls ]; then cp -r plugins/tls "$out/share/swiftpoint/plugins/"; fi
    if [ -d plugins/wayland-shell-integration ]; then cp -r plugins/wayland-shell-integration "$out/share/swiftpoint/plugins/"; fi
    if [ -d plugins/wayland-decoration-client ]; then cp -r plugins/wayland-decoration-client "$out/share/swiftpoint/plugins/"; fi

    ln -s "$out/share/swiftpoint/Swiftpoint X1 Control Panel" "$out/bin/swiftpoint-x1-control-panel"

    mkdir -p "$out/lib/udev/rules.d"
    cp 60-Swiftpoint.rules "$out/lib/udev/rules.d/"

    mkdir -p "$out/share/applications"
    cp "${desktopItem}/share/applications/"* "$out/share/applications/"

    install -Dm644 ${../assets/logo.png} \
      "$out/share/pixmaps/swiftpoint-x1-control-panel.png"

    runHook postInstall
  '';

  preFixup = ''
    autoPatchelfOptions+=(--libs "${qt6.qtwayland}/lib")
  '';

  postFixup = ''
    wrapProgram "$out/bin/swiftpoint-x1-control-panel" \
      --run ${lib.escapeShellArg configureUserSettings}
  '';

  qtWrapperArgs = [
    "--prefix LD_LIBRARY_PATH : ${builtins.placeholder "out"}/share/swiftpoint/lib"
  ];

  passthru = {
    inherit (release) channel;
    inherit configureUserSettings;
    swiftpointX1ControlPanel = true;
    updateScript = ../update.sh;
  };

  meta = {
    description = "Swiftpoint X1 Control Panel for mouse management";
    homepage = "https://support.swiftpoint.com/portal/en/kb/articles/x1-control-panel-linux";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "swiftpoint-x1-control-panel";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
