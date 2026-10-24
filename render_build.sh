#!/usr/bin/env bash
set -e

echo "==> Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
export PATH="/opt/flutter/bin:$PATH"

echo "==> Flutter version"
flutter --version --no-version-check

echo "==> Accepting licenses & pre-caching web tools"
flutter config --enable-web
flutter precache --web

echo "==> Getting packages"
flutter pub get

echo "==> Building Flutter Web (no-wasm)"
flutter build web --release --no-wasm-dry-run

echo "==> Done! build/web is ready."
