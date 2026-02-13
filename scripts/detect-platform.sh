#!/bin/bash
# Detects platform and outputs: linux or macos

case "$(uname -s)" in
    Linux*)  echo "linux";;
    Darwin*) echo "macos";;
    *)       echo "unknown"; exit 1;;
esac
