#!/bin/bash

# Deletes everything but the newest builds of a package in a distribution.
#
# Usage: clean-oldies.sh <dist> <package>

set -u

: "${REPO_DIR:?REPO_DIR must be set}"

DEST="${REPO_DIR}/$1"

# Deletes everything but the newest files matching the specified pattern
clean_oldies() {
    pattern="$1"
    leaveCount="$2"

    # shellcheck disable=SC2086
    ls -t $pattern 2>/dev/null | tail -n +$((leaveCount + 1)) | xargs -r rm -f
}

# Deletes all but the newest <count> deb, changes and buildinfo files of a package
clean_package() {
    for ext in deb changes buildinfo; do
        clean_oldies "${DEST}/$1_*$3.${ext}" "$2"
    done
}

case "$2" in
  jibri|jigasi|jitsi-upload-integrations|jitsi-autoscaler-sidecar|token-generator)
    clean_package "$2" 20 all
    ;;
  jicofo|jitsi-videobridge2)
    clean_package "$2" 40 all
    ;;
  jitsi-meet)
    clean_package jitsi-meet 200 all
    ;;
  jitsi-meet-web)
    clean_package jitsi-meet-web 200 all
    clean_oldies "${DEST}/jitsi-meet-web-config_*all.deb" 200
    clean_oldies "${DEST}/jitsi-meet-prosody_*all.deb" 200
    clean_oldies "${DEST}/jitsi-meet-turnserver_*all.deb" 200
    ;;
  *)
    echo "Unknown package $2 in clean oldies"
    exit 3
    ;;
esac
