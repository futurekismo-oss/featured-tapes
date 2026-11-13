#!/usr/bin/env bash

set -u

git clone https://github.com/caelestia-dots/caelestia.git

mv caelestia/* .
rm -rf caelestia

mkdir quickshell
git clone https://github.com/caelestia-dots/shell.git quickshell/caelestia

cd quickshell/caelestia || exit

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/

cmake --build build
sudo cmake --install build




