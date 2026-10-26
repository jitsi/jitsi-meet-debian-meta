#!/bin/bash

# Promotes packages from one distribution to another (unstable -> testing -> stable).
#
# Usage:
#   promote.sh <from> <to> <jitsi-meet version>
#       promotes the jitsi-meet meta package and the jitsi-meet-web, jicofo and jitsi-videobridge2
#       versions it depends on; when promoting to stable also creates the github releases
#   promote.sh <from> <to> <version> <package>...
#       promotes the given version of the listed packages, e.g. jibri

set -e -u -x

: "${REPO_DIR:?REPO_DIR must be set}"

FROM_REPO=$1
TO_REPO=$2
VERSION=$3
shift 3
PACKAGES=("$@")

THIS_DIR=$(cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" && pwd)
INCOMING="${REPO_DIR}/mini-dinstall/incoming"

# Copies the files matching the pattern from the source distribution to incoming,
# unless they are already in the destination one.
copyToIncoming() {
    local files=$1
    if eval ls "${REPO_DIR}/${TO_REPO}/${files}" 1> /dev/null 2>&1; then
        echo "Files already exist ${files}!"
    else
        eval cp "${REPO_DIR}/${FROM_REPO}/${files}" "${INCOMING}"
    fi
}

if [ ${#PACKAGES[@]} -eq 0 ]; then
    # get-versions.sh resolves the dependencies of the jitsi-meet package through apt
    sudo apt-get update
    jitsi_meet="${VERSION}-*"
    # shellcheck source=../../get-versions.sh
    . "${THIS_DIR}/../../get-versions.sh" "${jitsi_meet}"

    copyToIncoming "jitsi-meet-*${jitsi_meet_web}*.{changes,deb,buildinfo}"
    copyToIncoming "jitsi-videobridge*${jitsi_videobridge2}*.{changes,deb,buildinfo}"
    copyToIncoming "jicofo*${jicofo}*.{changes,deb,buildinfo}"
    copyToIncoming "jitsi-meet_*${jitsi_meet}*.{changes,deb,buildinfo}"

    PACKAGES=(jitsi-meet jitsi-videobridge2 jicofo jitsi-meet-web)
else
    for p in "${PACKAGES[@]}"; do
        copyToIncoming "${p}_*${VERSION}*.{changes,deb,buildinfo}"
    done
fi

sed -i.bak -e "s/Distribution: ${FROM_REPO}/Distribution: ${TO_REPO}/" "${INCOMING}"/*.changes
rm -f "${INCOMING}"/*.bak

# as we are promoting a build to stable, let's clean testing
if [ "${TO_REPO}" == "stable" ]; then
    for p in "${PACKAGES[@]}"; do
        "${THIS_DIR}/clean-oldies.sh" testing "$p"
    done

    if [ -n "${jitsi_meet_web_min:-}" ] && [ -z "${DRY_RUN:-}" ]; then
        "${THIS_DIR}/github-release.sh" "${TO_REPO}" "${VERSION}" \
            "${jitsi_meet_web_min}" "${jicofo_min}" "${jitsi_videobridge_min}"
    fi
fi

"${THIS_DIR}/update-repo.sh"

if [ "${TO_REPO}" == "stable" ]; then
    "${THIS_DIR}/move-and-clean-signatures.sh"
fi

"${THIS_DIR}/sync-repo.sh" "${TO_REPO}"

# testing was cleaned up as well
if [ "${TO_REPO}" == "stable" ]; then
    "${THIS_DIR}/sync-repo.sh" testing
fi
