#!/bin/bash

# Copies the signatures of the packages promoted to stable from unstable
# and moves away the unstable signatures of packages no longer in unstable.

set -u

: "${REPO_DIR:?REPO_DIR must be set}"

STALE_DIR=${STALE_SIGNATURES_DIR:-$(mktemp -d)}

for file in "${REPO_DIR}"/stable/*; do
    fileName=$(basename "$file")
    if ! [ -f "${REPO_DIR}/stable/signatures/$fileName.asc" ] && [ -f "${REPO_DIR}/unstable/signatures/$fileName.asc" ]; then
        cp "${REPO_DIR}/unstable/signatures/$fileName.asc" "${REPO_DIR}/stable/signatures/"
    fi
done

for file in "${REPO_DIR}"/unstable/signatures/*; do
    fileName=$(basename "${file%.asc}")
    if ! [ -f "${REPO_DIR}/unstable/$fileName" ]; then
        mv "$file" "${STALE_DIR}/"
    fi
done
