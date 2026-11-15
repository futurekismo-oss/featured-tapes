#!/usr/bin/env bash

set -u

git clone --depth 1 https://github.com/ilyamiro/serpantinum.git

mkdir serpantinum-shell
mv serpantinum/{bin,src,version.txt} serpantinum-shell/
mv serpantinum/compositors/hyprland hypr
mv serpantinum/config/kitty kitty
rm -rf serpantinum

cd serpantinum-shell/bin || exit

curl -fsSL https://github.com/ilyamiro/serpantinum-core/releases/download/v0.6.1/serpantinum-core-0.6.1-x86_64-linux.tar.gz | tar -xz --strip-components=2 usr/bin
curl -fsSL https://github.com/ilyamiro/serpantinum-audio/releases/download/v0.4.0/serpantinum-audio-0.4.0-x86_64-linux.tar.gz | tar -xz --strip-components=2 usr/bin
curl -fsSL https://github.com/ilyamiro/serpantinum-gamma/releases/download/v0.7.0/serpantinum-gamma-0.7.0-x86_64-linux.tar.gz | tar -xz --strip-components=2 usr/bin

mkdir -p ~/.local/bin
ln -sf "$PWD"/* ~/.local/bin/

cd ../.. && rm -rf setup.sh
