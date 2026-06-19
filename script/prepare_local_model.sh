#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_CACHE="$ROOT_DIR/.build/cache"

mkdir -p "$LOCAL_CACHE" "$ROOT_DIR/.build/module-cache"
export XDG_CACHE_HOME="$LOCAL_CACHE"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache"

swift run GlossaModelPrep "$@"
