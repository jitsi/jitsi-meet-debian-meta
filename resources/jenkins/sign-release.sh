#!/bin/bash

# mini-dinstall release_signscript, signs the Release file passed as the only argument.
# Produces Release.gpg and InRelease in the current directory.

set -e

: "${GNUPGHOME:?GNUPGHOME must be set}"
GPG_KEY_ID=${GPG_KEY_ID:-Jitsi}
GPG_PASSPHRASE_FILE=${GPG_PASSPHRASE_FILE:-$GNUPGHOME/passphrase}

rm -f Release.gpg.tmp InRelease.tmp
gpg --no-tty --batch --passphrase-file "${GPG_PASSPHRASE_FILE}" --default-key "${GPG_KEY_ID}" \
    --detach-sign -o Release.gpg.tmp "$1"
mv Release.gpg.tmp Release.gpg
gpg --no-tty --batch --passphrase-file "${GPG_PASSPHRASE_FILE}" --default-key "${GPG_KEY_ID}" \
    --clearsign -o InRelease.tmp "$1"
mv InRelease.tmp InRelease
