#!/usr/bin/env bash
set -e

echo "==> Setting up Flutter SDK..."
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR/bin" ]; then
  echo "==> Downloading Flutter (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
else
  echo "==> Flutter already cached at $FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "==> Flutter version:"
flutter --version --no-version-check

echo "==> Pre-caching Web artifacts..."
flutter config --enable-web
flutter precache --web

echo "==> Getting packages..."
flutter pub get

echo "==> Building Flutter Web for Production..."
flutter build web --release --no-wasm-dry-run

echo "==> Build successful! Artifacts ready in build/web"

