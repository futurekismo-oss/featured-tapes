{
  pkgs,
  lib,
  inputs,
  ...
}: let
  qmlPrefix = pkgs.qt6.qtbase.qtQmlPrefix;
  pluginPrefix = pkgs.qt6.qtbase.qtPluginPrefix;

  m3shapes = pkgs.stdenv.mkDerivation {
    pname = "m3shapes";
    version = "1.0.0";
    src = inputs.m3shapes;

    nativeBuildInputs = [
      pkgs.cmake
      pkgs.ninja
      pkgs.qt6.wrapQtAppsHook
    ];

    buildInputs = [
      pkgs.qt6.qtbase
      pkgs.qt6.qtdeclarative
      pkgs.qt6.qtshadertools
    ];

    dontWrapQtApps = true;

    cmakeFlags = [
      "-DM3SHAPES_BUILD_EXAMPLES=OFF"
    ];

    meta = {
      description = "Material 3 Expressive shapes QML plugin for Qt6";
      homepage = "https://github.com/soramanew/m3shapes";
      platforms = lib.platforms.linux;
    };
  };

  qtModules = [
    pkgs.qt6.qtmultimedia
    pkgs.qt6.qtimageformats
  ];

  qmlDirs =
    ["${m3shapes}/lib/qt6/qml"]
    ++ map (p: "${p}/${qmlPrefix}") qtModules;
  pluginDirs = map (p: "${p}/${pluginPrefix}") qtModules;

  tape = pkgs.runCommand "featured-tape-nebula" {} ''
    mkdir -p "$out"
    for item in hypr quickshell matugen ghostty; do
      if [ -e "${inputs.nebula-dots}/$item" ]; then
        cp -r "${inputs.nebula-dots}/$item" "$out/$item"
      fi
    done
    chmod -R u+w "$out"

    if [ -f "$out/hypr/hyprland/execs.lua" ]; then
      sed -i \
        -e "s#/usr/lib/mate-polkit/polkit-mate-authentication-agent-1#${pkgs.mate-polkit}/libexec/polkit-mate-authentication-agent-1#g" \
        "$out/hypr/hyprland/execs.lua"
    fi

    sed \
      -e '/^install =/d' \
      -e "s#\"pkill -x qs\"#\"pkill -x 'qs|quickshell|[.]quickshell-wra' || true\"#g" \
      ${./tape.toml} > "$out/tape.toml"
  '';
in {
  name = "nebula";
  inherit tape qmlDirs pluginDirs;
  needsQuickshell = true;

  packages =
    qtModules
    ++ [m3shapes]
    ++ (with pkgs; [
      matugen
      ghostty
      wl-clipboard
      cliphist
      fuzzel
      hypridle
      hyprlock
      brightnessctl
      wireplumber
      pipewire
      playerctl
      grim
      slurp
      jq
      cava
      gpu-screen-recorder
      ffmpeg
      zenity
      libnotify
      networkmanager
      pciutils
      xdg-utils
      fastfetch
      dbus
      mate-polkit
      material-symbols
      inter
      nerd-fonts.symbols-only
      papirus-icon-theme
      qt6.qtdeclarative
      qt6.qtshadertools
    ]);

  env = {
    NIXPKGS_QT6_QML_IMPORT_PATH = lib.concatStringsSep ":" qmlDirs;
    QML2_IMPORT_PATH = lib.concatStringsSep ":" qmlDirs;
    QT_PLUGIN_PATH = lib.concatStringsSep ":" pluginDirs;
  };
}
