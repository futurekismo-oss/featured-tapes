{
  description = "Official curated rices for Tapes v2, with declarative NixOS & Home Manager support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    caelestia-dots = {
      url = "github:caelestia-dots/caelestia";
      flake = false;
    };
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    end-4-dots = {
      url = "github:end-4/dots-hyprland";
      flake = false;
    };
    end-4-rounded-polygon = {
      url = "github:end-4/rounded-polygon-qmljs";
      flake = false;
    };
    nebula-dots = {
      url = "github:LilaccFlowerr/Nebula";
      flake = false;
    };
    m3shapes = {
      url = "github:soramanew/m3shapes";
      flake = false;
    };
    noctalia-libre-dots = {
      url = "github:futurekismo-oss/noctalia-libre";
      flake = false;
    };
    serpantinum-dots = {
      url = "github:ilyamiro/serpantinum";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs: let
    riceNames = [
      "caelestia"
      "end-4"
      "nebula"
      "noctalia-libre"
      "serpantinum"
    ];

    loadRices = system: pkgs:
      nixpkgs.lib.genAttrs riceNames (name:
        import ./${name}/default.nix {
          inherit pkgs inputs system;
          lib = pkgs.lib;
        });

    mkWrappedQuickshell = pkgs: qmlDirs: pluginDirs: let
      uQml = nixpkgs.lib.unique qmlDirs;
      uPlug = nixpkgs.lib.unique pluginDirs;
    in
      if uQml == [] && uPlug == []
      then pkgs.quickshell
      else
        pkgs.runCommand "quickshell-wrapped-${pkgs.quickshell.version}" {
          nativeBuildInputs = [pkgs.makeWrapper];
        } ''
          mkdir -p "$out/bin"
          for prog in qs quickshell; do
            if [ -e "${pkgs.quickshell}/bin/$prog" ]; then
              makeWrapper "${pkgs.quickshell}/bin/$prog" "$out/bin/$prog" \
                --prefix NIXPKGS_QT6_QML_IMPORT_PATH : "${nixpkgs.lib.concatStringsSep ":" uQml}" \
                --prefix QML2_IMPORT_PATH : "${nixpkgs.lib.concatStringsSep ":" uQml}" \
                --prefix QT_PLUGIN_PATH : "${nixpkgs.lib.concatStringsSep ":" uPlug}"
            fi
          done
        '';

    ricePackages = pkgs: r:
      r.packages
      ++ nixpkgs.lib.optional (r.needsQuickshell or false) (
        mkWrappedQuickshell pkgs (r.qmlDirs or []) (r.pluginDirs or [])
      );

    mkHomeModule = defaultEnabled: {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.programs.featured-tapes;
      system = pkgs.stdenv.hostPlatform.system;
      rices = loadRices system pkgs;
      selected = map (name: rices.${name}) cfg.tapes;
      anyQuickshell = lib.any (r: r.needsQuickshell or false) selected;
      allQmlDirs = lib.concatMap (r: r.qmlDirs or []) selected;
      allPluginDirs = lib.concatMap (r: r.pluginDirs or []) selected;
    in {
      options.programs.featured-tapes = {
        enable = lib.mkEnableOption "Declarative featured tapes and their Nix runtime dependencies";

        tapes = lib.mkOption {
          type = lib.types.listOf (lib.types.enum riceNames);
          default = defaultEnabled;
          example = ["caelestia" "nebula" "noctalia-libre"];
          description = "Featured tapes to seed into `~/.tapes/<name>` along with their Nix runtime packages.";
        };

        rename = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {};
          example = {
            nebula = "nebula-nix";
            caelestia = "caelestia-official";
          };
          description = ''
            Optional map of `<featured-rice> -> <custom-name>` to install a tape into
            `~/.tapes/<custom-name>` instead of `~/.tapes/<featured-rice>` (equivalent to
            `tapes install --name`), avoiding collisions with manually installed tapes.
          '';
        };
      };

      config = lib.mkIf (cfg.enable && cfg.tapes != []) {
        home.packages =
          (lib.concatMap (r: r.packages) selected)
          ++ lib.optional anyQuickshell (mkWrappedQuickshell pkgs allQmlDirs allPluginDirs);

        home.sessionVariables =
          lib.zipAttrsWith (
            _: values:
              lib.concatStringsSep ":" (lib.unique (lib.concatMap (lib.splitString ":") values))
          ) (map (r: r.env) selected);

        # Seed plain writable copies into ~/.tapes/<target> (zero /nix/store symlinks inside ~/.tapes)
        # so runtime tools (matugen, noctalia, caelestia-cli, btop) and tapes-deck work without EROFS
        # or chained symlinks, while preserving any existing user edits across rebuilds.
        home.activation.seedFeaturedTapes = lib.hm.dag.entryAfter ["linkGeneration"] (
          ''
            mkdir -p "$HOME/.tapes"
          ''
          + lib.concatMapStringsSep "\n" (r: let
            targetName = cfg.rename.${r.name} or r.name;
          in ''
            if [ ! -e "$HOME/.tapes/${targetName}/tape.toml" ]; then
              rm -rf "$HOME/.tapes/${targetName}"
              mkdir -p "$HOME/.tapes/${targetName}"
              cp -r --no-preserve=mode "${r.tape}/." "$HOME/.tapes/${targetName}/"
              chmod -R u+w "$HOME/.tapes/${targetName}"
            else
              cp -rn --no-preserve=mode "${r.tape}/." "$HOME/.tapes/${targetName}/" 2>/dev/null || true
              chmod -R u+w "$HOME/.tapes/${targetName}"
            fi
          '')
          selected
        );
      };
    };
  in
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system: let
      pkgs = import nixpkgs {inherit system;};
      rices = loadRices system pkgs;

      tapePackages = nixpkgs.lib.mapAttrs' (name: r: {
        name = "${name}-tape";
        value = r.tape;
      }) rices;

      envPackages = nixpkgs.lib.mapAttrs (name: r:
        pkgs.symlinkJoin {
          name = "featured-tape-${name}-deps";
          paths = ricePackages pkgs r;
        })
      rices;
    in {
      packages = tapePackages // envPackages;

      devShells = nixpkgs.lib.mapAttrs (name: r:
        pkgs.mkShell {
          name = "tape-${name}";
          packages = ricePackages pkgs r;
          shellHook = ''
            ${nixpkgs.lib.concatStringsSep "\n" (nixpkgs.lib.mapAttrsToList (
              k: v:
                if nixpkgs.lib.hasSuffix "_PATH" k
                then ''export ${k}="${v}''${${k}:+:''$${k}}"''
                else ''export ${k}="${v}"''
            ) r.env)}
            echo "Featured tape '${name}' runtime environment loaded."
            echo "Try it with: tapes insert -p ${r.tape}"
          '';
        })
      rices;
    })
    // {
      lib = {
        inherit riceNames loadRices;
      };

      homeManagerModules =
        {
          default = mkHomeModule [];
        }
        // nixpkgs.lib.genAttrs riceNames (name: {
          imports = [self.homeManagerModules.default];
          programs.featured-tapes = {
            enable = nixpkgs.lib.mkDefault true;
            tapes = [name];
          };
        });
    };
}
