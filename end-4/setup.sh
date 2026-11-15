#!/usr/bin/env bash

set -u

git clone --recurse-submodules https://github.com/end-4/dots-hyprland end-4


mv end-4/dots/.config/* .
rm -rf end-4

rm -rf setup.sh

