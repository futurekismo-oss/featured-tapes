{
  pkgs,
  lib,
  inputs,
  system,
  ...
}: let
  caelestiaShell =
    if inputs.caelestia-shell.packages.${system} ? with-cli
    then inputs.caelestia-shell.packages.${system}.with-cli
    else inputs.caelestia-shell.packages.${system}.default;

  tape = pkgs.runCommand "featured-tape-caelestia" {} ''
    mkdir -p "$out"
    for item in btop fastfetch fish foot hypr micro starship.toml thunar; do
      if [ -e "${inputs.caelestia-dots}/$item" ]; then
        cp -r "${inputs.caelestia-dots}/$item" "$out/$item"
      fi
    done
    chmod -R u+w "$out"

    # Pre-seed scheme/current.lua so Hyprland Lua config loads cleanly even before first scheme write.
    if [ -f "$out/hypr/scheme/default.lua" ] && [ ! -e "$out/hypr/scheme/current.lua" ]; then
      cp "$out/hypr/scheme/default.lua" "$out/hypr/scheme/current.lua"
    fi

    # Patch hardcoded Arch /usr/lib daemon paths to Nix store paths.
    if [ -f "$out/hypr/hyprland/execs.lua" ]; then
      sed -i \
        -e "s#/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1#${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1#g" \
        -e "s#/usr/lib/geoclue-2.0/demos/agent#${pkgs.geoclue2}/libexec/geoclue-2.0/demos/agent#g" \
        "$out/hypr/hyprland/execs.lua"
    fi

    # Strip imperative Arch setup.sh install hook and adapt hooks for wrapped NixOS binaries.
    sed \
      -e '/^install =/d' \
      -e "s#\"pkill -x qs\"#\"pkill -x 'qs|quickshell|[.]quickshell-wra' || true\"#g" \
      -e 's#"qs -c caelestia -d"#"caelestia-shell -d"#g' \
      ${./tape.toml} > "$out/tape.toml"
  '';
in {
  name = "caelestia";
  inherit tape;

  packages = with pkgs; [
    caelestiaShell
    ddcutil
    brightnessctl
    cava
    swappy
    fish
    foot
    btop
    fastfetch
    micro
    starship
    thunar
    wireplumber
    libnotify
    gammastep
    bluez
    gnome-keyring
    polkit_gnome
    geoclue2
    glib
    trash-cli
    pwvucontrol
    qtengine
    cliphist
    wl-clipboard
    fuzzel
    ydotool
    hyprpicker
    hyprcursor
    material-symbols
    rubik
    nerd-fonts.caskaydia-cove
    nerd-fonts.jetbrains-mono
  ];

  env = {};
}
