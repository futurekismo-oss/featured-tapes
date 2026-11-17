# Contributing

Thanks for wanting to add your tape! However before we begin you will have to follow a few guidelines to add your dotfiles.

## Structure

Every tape has its own folder with the following files:

```
<tape-name>/
├── tape.toml    # required, contains the tape description, and its hooks
└── setup.sh     # optional but recommended, use it if the tape needs to fetch or build something before it can work
```

Use a lowercase folder name (`end-4`, `serpantinum`). The folder is what gets linked in the README.

## tape.toml

example:
```toml
[tape]
name = "caelestia"
desc = "A fluid, morphing interface to your Linux desktop"
dependencies = ["ninja", "Hyprland", "quickshell"]

[hooks]
insert = ["hyprctl reload", "pkill -x qs", "qs -c caelestia -d"]
eject = ["hyprctl reload", "pkill -x qs"]

install = ["chmod +x ./setup.sh", "./setup.sh"]
```

| Key | Required | What it does |
| --- | --- | --- |
| `[tape].name` | yes | Name of the tape. |
| `[tape].desc` | no, but expected | A short description of the tape. |
| `[tape].dependencies` | no, but expected | What the user needs to install for the tape to work. This will only list the dependencies, the user installs them themselves. |
| `[hooks].insert` | no, but expected | Shell commands run after the tape is inserted. |
| `[hooks].eject` | no, but expected | Shell commands run after the tape is ejected. Should undo what `insert` has done. |
| `install` | no, but expected if there is a `setup.sh` | Commands run when the tape is installed. Usually runs `setup.sh`. |

Notes:

- Hooks can use `$TAPE_NAME`, `$TAPE_DIR` and `$CONFIG_DIR`.
- Keep `insert` and `eject` symmetrical: whatever `insert` starts, `eject` stops.
- List every real dependency, including the compositor.

## setup.sh rules

`setup.sh` runs on the user's machine, so keep it boring.

- **Everything stays inside the tape's own folder (`~/.tapes/<tape>`).** Do not write, move or delete anything outside it, with one exception: binaries, see below. Do not touch `~/.config` yourself, tapes links the config when the tape is inserted.
- **Binaries go in `~/.tapes/bin`.** If your tape ships executables, symlink them into `~/.tapes/bin` (create it with `mkdir -p`). Do not link or move files to `~/.local/bin`, `/usr/local/...` or any other place outside the tape's folder.
- **No `sudo`** and no system-wide installs. List what is needed in `dependencies` so the user can install it themselves.
- **No emojis** in the script or its output.
- Start with `set -u` (or stricter).
- Pin versions of anything you download: use a tag or release, not `latest` or a branch.
- Only download from the project's own repositories or releases.
- Clean up after yourself (temporary clones, the script itself if it is single use). See the other featured tapes for examples.
- Keep it short. If it needs to do a lot, it is probably too much for a featured tape.

`~/.tapes/bin` is not on `PATH` by default, so if your script links binaries there, you could print how to add it at the end (see `serpantinum/setup.sh` for an example).

## Adding the tape to the README

Add a line to the list in [README.md](README.md), in the same format as the others, in alphabetical order:

```md
- [Name](https://github.com/futurekismo-oss/featured-tapes/tree/main/<folder>)
```

## AI usage

AI is allowed, but with skepticism. This follows the policy of [tapes](https://github.com/futurekismo-oss/tapes).

- You must fully understand everything you submit, especially `setup.sh` and the hooks, since they run on other people's machines.
- You are liable for errors in your contribution.
- Do not use AI to write READMEs or documentation.
- Fully agentic commits (an AI committing on its own) are not allowed.
- Use AI the way you would use Stack Overflow.

## Pull requests

- Do not push to `main`. Use a branch or a fork and open a PR.
- Read earlier commit messages and match their style.
- Test it: insert the tape, check that it works, eject it, check that everything it started is gone.
- Mention in the PR where the tape comes from and under which license.

The guidelines are lenient. Follow the spirit where you cannot follow every detail.