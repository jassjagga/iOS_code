#!/bin/sh
find "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" -type f -name "*.framework" -exec chmod u+w {} \;


