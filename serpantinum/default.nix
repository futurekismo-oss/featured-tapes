{
  pkgs,
  lib,
  inputs,
  ...
}: let
  qmlPrefix = pkgs.qt6.qtbase.qtQmlPrefix;
  pluginPrefix = pkgs.qt6.qtbase.qtPluginPrefix;
  isX86_64 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";

  qtModules = [
    pkgs.qt6.qtmultimedia
    pkgs.qt6.qtimageformats
  ];

  qmlDirs = map (p: "${p}/${qmlPrefix}") qtModules;
  pluginDirs = map (p: "${p}/${pluginPrefix}") qtModules;

  mkHelper = {
    pname,
    version,
    url,
    hash,
    buildInputs ? [],
  }:
    pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = pkgs.fetchurl {inherit url hash;};

      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [pkgs.stdenv.cc.cc.lib] ++ buildInputs;

      unpackPhase = ''
        tar -xzf "$src"
      '';

      installPhase = ''
        install -Dm755 usr/bin/${pname} "$out/bin/${pname}"
      '';
    };

  serpantinumHelpers = lib.optionals isX86_64 [
    (mkHelper {
      pname = "serpantinum-core";
      version = "0.6.1";
      url = "https://github.com/ilyamiro/serpantinum-core/releases/download/v0.6.1/serpantinum-core-0.6.1-x86_64-linux.tar.gz";
      hash = "sha256-bsWSUWVcTGRjMIkKXPDAQjHqHKyHQ0vbx+OPHuTyAd8=";
    })
    (mkHelper {
      pname = "serpantinum-audio";
      version = "0.4.0";
      url = "https://github.com/ilyamiro/serpantinum-audio/releases/download/v0.4.0/serpantinum-audio-0.4.0-x86_64-linux.tar.gz";
      hash = "sha256-jBrJYLO/am8GrJ0P+2p6ku8ysGvnrsKN5dkV22tG8o0=";
      buildInputs = [pkgs.pipewire];
    })
    (mkHelper {
      pname = "serpantinum-gamma";
      version = "0.7.0";
      url = "https://github.com/ilyamiro/serpantinum-gamma/releases/download/v0.7.0/serpantinum-gamma-0.7.0-x86_64-linux.tar.gz";
      hash = "sha256-lCulTqtK1/3OY05htsISu/wUwncRFfTxstNw8yZGrgQ=";
    })
  ];

  serpantinumShell = pkgs.stdenv.mkDerivation {
    pname = "serpantinum-shell";
    version = "2.5.1";
    src = inputs.serpantinum-dots;

    nativeBuildInputs = [pkgs.makeWrapper];

    dontBuild = true;

    installPhase = ''
      mkdir -p "$out/share/serpantinum-shell" "$out/bin"
      for item in bin src version.txt; do
        if [ -e "$src/$item" ]; then
          cp -r "$src/$item" "$out/share/serpantinum-shell/$item"
        fi
      done
      chmod -R u+w "$out/share/serpantinum-shell"
      chmod +x "$out/share/serpantinum-shell/bin/"*

      for prog in serpantinum serpantinumd; do
        makeWrapper "$out/share/serpantinum-shell/bin/$prog" "$out/bin/$prog" \
          --set SERPANTINUM_DIR "$out/share/serpantinum-shell/src" \
          --prefix NIXPKGS_QT6_QML_IMPORT_PATH : "${lib.concatStringsSep ":" qmlDirs}" \
          --prefix QML2_IMPORT_PATH : "${lib.concatStringsSep ":" qmlDirs}" \
          --prefix QT_PLUGIN_PATH : "${lib.concatStringsSep ":" pluginDirs}" \
          --prefix PATH : "${lib.makeBinPath (
        with pkgs; [
          bash
          cliphist
          coreutils
          curl
          ffmpeg
          findutils
          gawk
          gnugrep
          gpu-screen-recorder
          grim
          imagemagick
          jq
          matugen
          playerctl
          procps
          pulseaudio
          python3
          quickshell
          satty
          tesseract
          util-linux
          wireplumber
          wl-clipboard
          xdg-utils
          zbar
        ]
        ++ serpantinumHelpers
      )}"
      done
    '';
  };

  tape = pkgs.runCommand "featured-tape-serpantinum" {} ''
    mkdir -p "$out/serpantinum-shell"
    for item in bin src version.txt; do
      if [ -e "${inputs.serpantinum-dots}/$item" ]; then
        cp -r "${inputs.serpantinum-dots}/$item" "$out/serpantinum-shell/$item"
      fi
    done
    if [ -d "${inputs.serpantinum-dots}/compositors/hyprland" ]; then
      cp -r "${inputs.serpantinum-dots}/compositors/hyprland" "$out/hypr"
    fi
    if [ -d "${inputs.serpantinum-dots}/config/kitty" ]; then
      cp -r "${inputs.serpantinum-dots}/config/kitty" "$out/kitty"
    fi

    sed \
      -e '/^install =/d' \
      -e "s#qs|quickshell#qs|quickshell|[.]quickshell-wra#g" \
      ${./tape.toml} > "$out/tape.toml"
  '';
in {
  name = "serpantinum";
  inherit tape qmlDirs pluginDirs;
  needsQuickshell = true;

  packages =
    qtModules
    ++ [serpantinumShell]
    ++ serpantinumHelpers
    ++ (with pkgs; [
      matugen
      wl-clipboard
      cliphist
      jq
      kitty
      grim
      satty
      wireplumber
      pulseaudio
      playerctl
      curl
      imagemagick
      ffmpeg
      gpu-screen-recorder
      tesseract
      zbar
      xdg-utils
      kdePackages.qt6ct
      jetbrains-mono
    ]);

  env = {
    NIXPKGS_QT6_QML_IMPORT_PATH = lib.concatStringsSep ":" qmlDirs;
    QML2_IMPORT_PATH = lib.concatStringsSep ":" qmlDirs;
    QT_PLUGIN_PATH = lib.concatStringsSep ":" pluginDirs;
  };
}
