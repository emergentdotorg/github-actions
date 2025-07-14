#!/bin/sh -l

DEST_DIR="/github/workspace/${INPUT_RESOURCES_DEST}"
mkdir -p "${DEST_DIR}"
cp -a "$SRC_DIR"/* "${DEST_DIR}/"

printf '%s\n' \
  "time=$(date)" \
  "maven_user_settings=${INPUT_RESOURCES_DEST}/settings.xml" \
  >> "$GITHUB_OUTPUT"

exit 0
