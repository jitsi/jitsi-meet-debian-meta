#!/bin/bash

# Syncs a distribution of the archive to the download server.
#
# Usage: sync-repo.sh <dist>

set -e -u

: "${REPO_DIR:?REPO_DIR must be set}"

DIST=$1

if [ -z "${REPO_SYNC_TARGET:-}" ] || [ -n "${DRY_RUN:-}" ]; then
    echo "Skipping sync of ${DIST}"
    exit 0
fi

# mini-dinstall leaves the changes files readable only by the current user
chmod -R +r "${REPO_DIR}/${DIST}"

rsync --delete -avH "${REPO_DIR}/${DIST}" "${REPO_SYNC_TARGET}/"
