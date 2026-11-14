#!/bin/bash

set -e

# Builds the web app into docs/ for local preview.
# Actual deployment to GitHub Pages is done by CI (.github/workflows/deploy-pages.yml);
# this script no longer commits anything.

BUILD_DIR="build/web"
DEPLOY_DIR="docs"
BASE_HREF="/timer-guy/"

echo "Building web app..."
rm -rf "$BUILD_DIR"

flutter build web --wasm --base-href="$BASE_HREF" --release

echo "Copying build to $DEPLOY_DIR/..."
rm -rf "${DEPLOY_DIR:?}/"*
cp -r "$BUILD_DIR"/* "$DEPLOY_DIR"

echo "Done. Preview with: cd $DEPLOY_DIR && python3 -m http.server"
