#!/usr/bin/env bash

set -u

git clone https://github.com/futurekismo-oss/noctalia-libre

mv noctalia-libre/* .
rm -rf noctalia-libre

rm -rf showcase.png README.md setup.sh
