{
  pkgs,
  lib,
  inputs,
  ...
}: let
  tape = pkgs.runCommand "featured-tape-noctalia-libre" {} ''
    mkdir -p "$out"
    for item in btop foot helix hypr mango noctalia; do
      if [ -e "${inputs.noctalia-libre-dots}/$item" ]; then
        cp -r "${inputs.noctalia-libre-dots}/$item" "$out/$item"
      fi
    done

    sed \
      -e '/^install =/d' \
      -e 's#mmsg dispatch reload_config#mmsg -s -d reload_config#g' \
      -e "s#\"noctalia -d\"#\"pkill -x 'qs|quickshell|[.]quickshell-wra|noctalia' || true\", \"noctalia -d\"#g" \
      -e 's#"pkill noctalia"#"pkill -x noctalia || true"#g' \
      ${./tape.toml} > "$out/tape.toml"
  '';
in {
  name = "noctalia-libre";
  inherit tape;

  packages = with pkgs; [
    (pkgs.noctalia or pkgs.noctalia-shell)
    mangowc
    foot
    btop
    helix
    cliphist
    pamixer
    hyprshot
    swayosd
    bibata-cursors
    wl-clipboard
    hyprpicker
    maple-mono.NF
    monocraft
  ];

  env = {};
}
