#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Vercel Flutter Web Build Script ==="

# 1. Clone Flutter SDK if not already present
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable branch)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable
else
  echo "Flutter SDK already cached locally."
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

echo "Using Flutter version:"
flutter --version

# 3. Enable Web support
echo "Enabling Flutter Web support..."
flutter config --enable-web

# 4. Precache Web artifacts
echo "Precaching Web build targets..."
flutter precache --web

# 5. Run pub get
echo "Fetching project dependencies..."
flutter pub get

# 6. Run build runner to generate Riverpod models
echo "Running build_runner to generate code..."
dart run build_runner build --delete-conflicting-outputs

# 7. Compile the Web app
echo "Building Flutter Web application (Release)..."
flutter build web --release

echo "=== Build Completed Successfully! ==="
