{
  pkgs,
  lib,
  inputs,
  ...
}: let
  qmlPrefix = pkgs.qt6.qtbase.qtQmlPrefix;
  pluginPrefix = pkgs.qt6.qtbase.qtPluginPrefix;

  qtModules = [
    pkgs.qt6.qt5compat
    pkgs.qt6.qtpositioning
    pkgs.qt6.qtmultimedia
    pkgs.qt6.qtimageformats
    pkgs.kdePackages.kirigami.unwrapped
    pkgs.kdePackages.qqc2-desktop-style
    pkgs.kdePackages.sonnet
    pkgs.kdePackages.syntax-highlighting
  ];

  qmlDirs = map (p: "${p}/${qmlPrefix}") qtModules;
  pluginDirs = map (p: "${p}/${pluginPrefix}") qtModules;

  end4Python = pkgs.python3.withPackages (ps:
    with ps; [
      opencv4
      numpy
      pillow
      materialyoucolor
      click
      pygobject3
      loguru
      tqdm
    ]);

  # Provides a Nix-backed ILLOGICAL_IMPULSE_VIRTUAL_ENV with bin/activate compatibility.
  end4Venv = pkgs.runCommand "end-4-python-venv" {} ''
    mkdir -p "$out/bin"
    for bin in "${end4Python}/bin/"*; do
      ln -s "$bin" "$out/bin/$(basename "$bin")"
    done
    cat > "$out/bin/activate" <<EOF
export VIRTUAL_ENV="$out"
export PATH="${end4Python}/bin:\$PATH"
EOF
  '';

  tape = pkgs.runCommand "featured-tape-end-4" {} ''
    mkdir -p "$out"
    if [ -d "${inputs.end-4-dots}/dots/.config" ]; then
      cp -r "${inputs.end-4-dots}/dots/.config/"* "$out/"
    fi
    chmod -R u+w "$out"

    # Populate the rounded-polygon-qmljs git submodule at quickshell/ii/modules/common/widgets/shapes.
    if [ -d "${inputs.end-4-rounded-polygon}" ]; then
      mkdir -p "$out/quickshell/ii/modules/common/widgets/shapes"
      cp -r "${inputs.end-4-rounded-polygon}/." "$out/quickshell/ii/modules/common/widgets/shapes/"
      chmod -R u+w "$out/quickshell/ii/modules/common/widgets/shapes"
    fi

    # Point ILLOGICAL_IMPULSE_VIRTUAL_ENV to the Nix-built Python environment.
    if [ -f "$out/hypr/hyprland/env.lua" ]; then
      sed -i \
        -e 's#home_dir \.\. "/\.local/state/quickshell/\.venv"#"${end4Venv}"#g' \
        "$out/hypr/hyprland/env.lua"
    fi

    # Match NixOS-wrapped Quickshell (.quickshell-wra) in idle & keybind scripts.
    if [ -f "$out/hypr/hypridle.conf" ]; then
      sed -i -e 's#pidof qs quickshell#pidof qs quickshell .quickshell-wra#g' "$out/hypr/hypridle.conf"
    fi
    if [ -f "$out/hypr/hyprland/keybinds.lua" ]; then
      sed -i -e 's#killall ydotool qs quickshell#killall ydotool qs quickshell .quickshell-wra#g' "$out/hypr/hyprland/keybinds.lua"
    fi

    sed \
      -e '/^install =/d' \
      -e "s#\"pkill -x qs\"#\"pkill -x 'qs|quickshell|[.]quickshell-wra' || true\"#g" \
      ${./tape.toml} > "$out/tape.toml"
  '';
in {
  name = "end-4";
  inherit tape qmlDirs pluginDirs;
  needsQuickshell = true;

  packages =
    qtModules
    ++ [end4Python]
    ++ lib.optional (pkgs ? kde-material-you-colors) pkgs.kde-material-you-colors
    ++ (with pkgs; [
      hypridle
      hyprlock
      hyprpicker
      hyprshot
      hyprsunset
      wl-clipboard
      cliphist
      fuzzel
      wlogout
      grim
      slurp
      swappy
      wf-recorder
      tesseract
      cava
      playerctl
      brightnessctl
      ddcutil
      wtype
      ydotool
      bc
      jq
      ripgrep
      rsync
      yq-go
      fish
      kitty
      starship
      eza
      matugen
      wireplumber
      pulseaudio
      libnotify
      psmisc
      gnome-keyring
      libsecret
      dbus
      geoclue2
      imagemagick
      ffmpeg
      mpvpaper
      libqalculate
      songrec
      translate-shell
      xdg-utils
      xdg-user-dirs
      glib
      networkmanager
      kdePackages.breeze
      kdePackages.breeze-icons
      kdePackages.plasma-integration
      kdePackages.qtstyleplugin-kvantum
      material-symbols
      rubik
      twemoji-color-font
      nerd-fonts.jetbrains-mono
      adw-gtk3
      bibata-cursors
    ]);

  env = {
    NIXPKGS_QT6_QML_IMPORT_PATH = lib.concatStringsSep ":" qmlDirs;
    QML2_IMPORT_PATH = lib.concatStringsSep ":" qmlDirs;
    QT_PLUGIN_PATH = lib.concatStringsSep ":" pluginDirs;
    ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${end4Venv}";
  };
}
