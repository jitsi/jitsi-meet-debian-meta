#!/bin/bash

# Signs the .deb files and moves them with their .changes and .buildinfo files to the mini-dinstall incoming dir.
# The detached signatures go to <dist>/signatures.
#
# Usage: add-to-incoming.sh <dist> <file>...

set -e -u

DIST=$1
shift

: "${REPO_DIR:?REPO_DIR must be set}"
: "${GNUPGHOME:?GNUPGHOME must be set}"
GPG_PASSPHRASE_FILE=${GPG_PASSPHRASE_FILE:-$GNUPGHOME/passphrase}

INCOMING="${REPO_DIR}/mini-dinstall/incoming"
SIGNATURES="${REPO_DIR}/${DIST}/signatures"
mkdir -p "${SIGNATURES}"

for f in "$@"; do
    if [[ "$f" == *.deb ]]; then
        gpg --batch --yes --passphrase-file "${GPG_PASSPHRASE_FILE}" -sba "$f"
        mv "$f.asc" "${SIGNATURES}/"
    fi
    mv "$f" "${INCOMING}/"
done

ls -l "${INCOMING}"
