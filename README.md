# Featured Tapes

A curated collection of ready-to-use **tapes** (desktop rices, dotfiles, and system configurations) built for use with [tapes][].

## Installation

Make sure you have the [tapes CLI][tapes] installed on your system, then install any featured tape with a single command:

```bash
tapes install-featured <TAPE-NAME>
```

For example:

```bash
tapes install-featured caelestia
```


## Available Tapes

| Tape | Install Command |
| :--- | :--- |
| **[Caelestia](https://github.com/caelestia-dots/caelestia)** | `tapes install-featured caelestia` |
| **[End-4](https://github.com/end-4/dots-hyprland)** | `tapes install-featured end-4` |
| **[Nebula](https://github.com/LilaccFlowerr/Nebula)** | `tapes install-featured nebula` |
| **[Serpantinum](https://github.com/ilyamiro/serpantinum)** | `tapes install-featured serpantinum` |
| **[Noctalia-Libre](https://github.com/futurekismo-oss/noctalia-libre)** | `tapes install-featured noctalia-libre` |


----

<details>
<summary><strong>NixOS & Home Manager</strong></summary>

Because `setup.sh` scripts target imperative distributions, this repository also provides a Nix flake that builds each tape cleanly into the Nix store and supplies its runtime packages, fonts, and QML plugins declaratively.

### Quick trial (without modifying your system)

```bash
nix develop github:futurekismo-oss/featured-tapes#nebula
# then follow the printed `tapes insert -p /nix/store/...` command
```

### Home Manager

Add `featured-tapes` to your flake inputs and enable the rices you want:

```nix
{
  imports = [ inputs.featured-tapes.homeManagerModules.default ];

  programs.featured-tapes = {
    enable = true;
    tapes = [ "caelestia" "nebula" "noctalia-libre" ];
    # Optional: install under custom folder names in ~/.tapes/ (equivalent to `tapes install --name`)
    # rename = { nebula = "nebula-nix"; };
  };
}
```

Each enabled rice is seeded as a plain, writable copy into `~/.tapes/<name>` (with no `/nix/store` symlinks inside the tape) along with its Nix runtime dependencies, QML plugins, and fonts, ready to insert via `tapes insert <name>` or `tapes-deck`. Existing tape directories are preserved across rebuilds.

</details>

----

## Contributing

Have a rice or dotfile setup you want to share with the community? Contributions are welcome! 

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request to learn about:
- Required directory structure
- The `tape.toml` manifest schema
- Rules and best practices for `setup.sh`


## Related

- **[tapes][tapes]** — The core CLI tool for managing, sharing, and applying desktop configurations.

[tapes]: https://github.com/futurekismo-oss/tapes
