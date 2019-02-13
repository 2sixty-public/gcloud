#!/bin/sh
set -e

ORG=$1
REPO=$2
OUTPUT=$3

curl -s https://api.github.com/repos/${ORG}/${REPO}/releases/latest \
  | grep browser_download_url \
  | grep linux \
  | cut -d '"' -f 4 \
  | xargs -n 1 curl -o ${OUTPUT} -L
