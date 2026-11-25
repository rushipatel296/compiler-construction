#!/usr/bin/env bash
# Compiles every stage to WebAssembly for the browser demo in docs/.
# Needs flex, bison and Emscripten (emcc) on PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/wasm"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

EMFLAGS=(-O2 -sMODULARIZE=1 -sSINGLE_FILE=1 -sINVOKE_RUN=0 -sEXIT_RUNTIME=1
         -sFORCE_FILESYSTEM=1 -sALLOW_MEMORY_GROWTH=1
         -sENVIRONMENT=web,worker,node
         -sEXPORTED_RUNTIME_METHODS=FS,callMain)

build() { # stage grammar-name extra-sources...
  local stage=$1 name=$2; shift 2
  local dir="$TMP/$stage"
  cp -r "$ROOT/$stage" "$dir"
  pushd "$dir" >/dev/null
  if [ -f "$name.y" ]; then
    bison -d "$name.y"
    flex "$name.l"
    emcc "${EMFLAGS[@]}" -sEXPORT_NAME="make_$stage" -o "$OUT/$stage.js" "$name.tab.c" lex.yy.c "$@"
  else
    flex "$name.l"
    emcc "${EMFLAGS[@]}" -sEXPORT_NAME="make_$stage" -o "$OUT/$stage.js" lex.yy.c
  fi
  popd >/dev/null
  echo "built docs/wasm/$stage.js"
}

build lexer lexer
build parser parser
build ast ast driver.c
build codegen codegen
build interpreter ast driver.c symtab.c ast_execute.c
