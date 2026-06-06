#!/bin/bash

set -e

BUILD_DIR="build/web"
DEPLOY_DIR="docs"
COMMIT_MSG="deploy to pages"
BASE_HREF="/timer-guy/"

build_flutter_web() {
    echo "Building web app..."

    rm -rf $BUILD_DIR

    if ! flutter build web --wasm \
        --base-href=$BASE_HREF \
        --release; then
        echo "Build failed :("
        exit 1
    fi
}

deploy_to_pages() {
    echo "Deploying to pages..."

    rm -rf "${DEPLOY_DIR:?}/"*

    if ! cp -r "$BUILD_DIR"/* "$DEPLOY_DIR"; then
        echo "Failed to copy build files :("
        exit 1
    fi

    git add .
    if git diff --staged --quiet; then
        echo "No changes to deploy :()"
        exit 0
    fi

    git commit -m "$COMMIT_MSG" && git push    
    echo "Deployment successful!"
}

build_flutter_web
deploy_to_pages