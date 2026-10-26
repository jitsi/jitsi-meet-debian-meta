#!/bin/bash

# Tags the component repos with jitsi-meet_<meta version>, using the component versions
# recorded in this repo (jicofo, jitsi-meet-web) and the lib-jitsi-meet commit used by jitsi-meet-web.
# Run from a directory where the repos can be cloned.
#
# Usage: tag-release.sh <meta version> [<lib-jitsi-meet commit>]

set -e -u -x

META_VERSION=$1
LIB_JITSI_MEET_VERSION=${2:-}

THIS_DIR=$(cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" && pwd)
META_DIR="${THIS_DIR}/../.."
TAG="jitsi-meet_${META_VERSION}"

# Checks out the given ref of a jitsi repo and tags it
tag_repo() {
    local repo=$1
    local ref=$2

    if [ ! -d "${repo}" ]; then
        git clone "git@github.com:jitsi/${repo}.git"
    fi
    (
        cd "${repo}"
        git checkout master
        git pull --rebase
        [ -z "${ref}" ] || git checkout "${ref}"
        git tag -a "${TAG}" -m "Tagged automatically by Jenkins"
        [ -n "${DRY_RUN:-}" ] || git push origin "${TAG}"
    )
}

(
    cd "${META_DIR}"
    git tag -a "${TAG}" -m "Tagged automatically by Jenkins"
    [ -n "${DRY_RUN:-}" ] || git push origin "${TAG}"
)

tag_repo jicofo "tags/$(cat "${META_DIR}/jicofo")"
tag_repo jitsi-meet "tags/$(cat "${META_DIR}/jitsi-meet-web")"
tag_repo lib-jitsi-meet "${LIB_JITSI_MEET_VERSION}"
