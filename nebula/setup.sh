#!/usr/bin/env bash

set -u

git clone https://github.com/LilaccFlowerr/Nebula.git nebula

mv nebula/{hypr,quickshell,matugen,ghostty} .
rm -rf nebula

git clone https://github.com/soramanew/m3shapes.git

cd m3shapes || exit

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib

cmake --build build
sudo cmake --install build

cd .. && rm -rf m3shapes

rm -rf setup.sh
