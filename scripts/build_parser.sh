#!/bin/bash
set -e

LANG_NAME=$1
if [ -z "$LANG_NAME" ]; then
  echo "Usage: ./build_parser.sh <language_name> (e.g. rust, javascript, typescript)"
  exit 1
fi

PARSERS_DIR="$HOME/.nide/parsers"
mkdir -p "$PARSERS_DIR"

echo "Building tree-sitter-$LANG_NAME..."

# Create a temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Clone the parser repo (shallow clone)
git clone --depth 1 "https://github.com/tree-sitter/tree-sitter-$LANG_NAME"
cd "tree-sitter-$LANG_NAME"

# Determine OS and compiler flags
OS=$(uname -s)
if [ "$OS" = "Darwin" ]; then
  EXT="dylib"
  SHARED_FLAG="-dynamiclib -Wl,-undefined,dynamic_lookup"
elif [ "$OS" = "Linux" ]; then
  EXT="so"
  SHARED_FLAG="-shared -fPIC"
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Compile the parser.c
echo "Compiling src/parser.c..."
cc $SHARED_FLAG -I src -o "$PARSERS_DIR/tree-sitter-$LANG_NAME.$EXT" src/parser.c

# Some parsers like typescript or cpp also have a scanner.c
if [ -f "src/scanner.c" ]; then
  echo "Compiling with src/scanner.c..."
  cc $SHARED_FLAG -I src -o "$PARSERS_DIR/tree-sitter-$LANG_NAME.$EXT" src/parser.c src/scanner.c
elif [ -f "src/scanner.cc" ]; then
  echo "Compiling with src/scanner.cc..."
  c++ $SHARED_FLAG -I src -o "$PARSERS_DIR/tree-sitter-$LANG_NAME.$EXT" src/parser.c src/scanner.cc
fi

echo "Success! Parser saved to: $PARSERS_DIR/tree-sitter-$LANG_NAME.$EXT"

# Cleanup
rm -rf "$TMP_DIR"
