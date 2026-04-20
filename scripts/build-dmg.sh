#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT=OptiTranslate
SCHEME=OptiTranslate
CONFIG=Release
BUILD_DIR=build
ARCHIVE_PATH="$BUILD_DIR/${PROJECT}.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/${PROJECT}.app"
DMG_PATH="$BUILD_DIR/${PROJECT}.dmg"

xcodebuild -project ${PROJECT}.xcodeproj -scheme ${SCHEME} -configuration ${CONFIG} archive -archivePath "$ARCHIVE_PATH" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

if [ -d "$APP_PATH" ]; then
  hdiutil create -volname "${PROJECT}" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"
  echo "Created $DMG_PATH"
else
  echo "Archive failed, app not found at $APP_PATH" >&2
  exit 1
fi
