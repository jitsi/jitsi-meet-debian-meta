#!/bin/bash

# Creates the stable/jitsi-meet_<n> tags and github releases (with changelogs) for jitsi-meet,
# jicofo and jitsi-videobridge and opens a PR with the release notes in jitsi-meet-release-notes.
# Run from a directory where the repos can be cloned.
#
# Usage: github-release.sh <dist> <jitsi-meet version, e.g. 2.0.10590> <jitsi-meet-web> <jicofo> <jvb>

set -e -u -x

: "${REPO_DIR:?REPO_DIR must be set}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN must be set}"

TO_REPO=$1
FULL_VERSION=$2
JITSI_MEET_WEB_VERSION=$3
JICOFO_VERSION=$4
JVB_VERSION=$5

# Converts 2.0.4966 or 2.0.4966-2 to 4966
VERSION=$(echo "${FULL_VERSION}" | cut -d '.' -f 3 | cut -d '-' -f 1)

GITHUB_API="https://api.github.com/repos"
GITHUB_UPLOAD_API="https://uploads.github.com/repos"

# the latest (timewise) jitsi-meet in the destination distribution is the previous stable
PREVIOUS_STABLE_FILENAME=$(basename "$(ls -t "${REPO_DIR}/${TO_REPO}"/jitsi-meet_*.deb | head -1)")
PREVIOUS_STABLE_VER=$(echo "${PREVIOUS_STABLE_FILENAME}" | sed -E 's/jitsi-meet_[0-9]+.[0-9]+.(.*)-[0-9].*deb/\1/')
PREV_STABLE_TO_NEW_STABLE_TAG_COMPARE="jitsi-meet_${PREVIOUS_STABLE_VER}..jitsi-meet_${VERSION}"
RELEASE_FILE=$(pwd)/${FULL_VERSION}-RELEASE-NOTES.txt

# Appends the features, fixes and translation updates from a changelog to the release notes
# $1 - source file
# $2 - destination file
filter_changelogs() {
    local src=$1
    local dst=$2

    echo -e "\t- New features:" >> "$dst"
    grep -i '* feat' "$src" | sed -e "s/^\* feat: //I" -e "s/^\* feature: //I" -e "s/^\* feat //I" \
        -e "s/^\* feature //I" -e "s/^\* //" -e 's/^/\t\t- /' >> "$dst" || true
    echo "" >> "$dst"
    echo -e "\t- Fixes:" >> "$dst"
    grep -i '* fix' "$src" | sed -e "s/^\* fix: //I" -e "s/^\* fix //I" -e "s/^\* //" -e 's/^/\t\t- /' >> "$dst" || true
    echo "" >> "$dst"
    if grep -qi '* lang' "$src"; then
        echo -e "\t- Translation updates:" >> "$dst"
        grep -i '* lang' "$src" | sed -e "s/^\* lang: //I" -e 's/^/\t\t- /' >> "$dst"
        echo "" >> "$dst"
    fi
}

# Calls the github API, with tracing turned off for the request
# $1 - url, the rest are passed to curl
github() {
    { set +x; } 2>/dev/null
    local url=$1
    shift
    curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$@" "$url"
    set -x
}

# Makes a release for a project
# $1 - the project name
# $2 - the version of the project
makeRelease() {
    local project=$1
    local ver=$2

    if [ ! -d "${project}" ]; then
        git clone "git@github.com:jitsi/${project}.git"
    fi
    cd "${project}"
    git checkout master
    git pull --rebase

    local chlog_file
    chlog_file=$(pwd)/../${project}_${ver}_CHANGELOG.txt
    echo "${project} ${ver}" > "${chlog_file}"
    echo "-----------" >> "${chlog_file}"
    echo "- [${project} ${ver}](https://github.com/jitsi/${project}/releases/tag/stable%2Fjitsi-meet_${VERSION})" >> "${RELEASE_FILE}"

    if [[ ${ver} == [[:digit:]]*.[[:digit:]]*-[[:digit:]]*-g[[:xdigit:]]* ]]; then
        # versions from git describe, 2.1-125-gaaaaaaa
        local githash
        githash=$(echo "${ver}" | cut -d'-' -f3 | cut -c2-)
        git log --pretty=format:"* %s%n" "stable/jitsi-meet_${PREVIOUS_STABLE_VER}..${githash}" > TMP_CHLOGS
        git checkout "${githash}"
    else
        git log --pretty=format:"* %s%n" "${PREV_STABLE_TO_NEW_STABLE_TAG_COMPARE}" > TMP_CHLOGS
        git checkout "jitsi-meet_${VERSION}"
    fi
    cat TMP_CHLOGS >> "${chlog_file}"
    filter_changelogs TMP_CHLOGS "${RELEASE_FILE}"
    rm TMP_CHLOGS

    # the lib-jitsi-meet changes are part of the jitsi-meet changelog
    if [ "${project}" = "jitsi-meet" ]; then
        cd ..
        if [ ! -d lib-jitsi-meet ]; then
            git clone git@github.com:jitsi/lib-jitsi-meet.git
        fi
        cd lib-jitsi-meet
        git checkout master
        git pull --rebase
        { echo; echo "******************************************************************"; echo
          echo "lib-jitsi-meet"; echo "-----------"; } >> "${chlog_file}"
        git log --pretty=format:"* %s%n" "${PREV_STABLE_TO_NEW_STABLE_TAG_COMPARE}" > TMP_CHLOGS
        cat TMP_CHLOGS >> "${chlog_file}"
        echo "" >> "${RELEASE_FILE}"
        echo -e "\tlib-jitsi-meet" >> "${RELEASE_FILE}"
        filter_changelogs TMP_CHLOGS "${RELEASE_FILE}"
        rm TMP_CHLOGS
        cd "../${project}"
    fi

    git tag -a "stable/jitsi-meet_${VERSION}" -m "Tagged automatically by Jenkins" || true
    git push origin "stable/jitsi-meet_${VERSION}" || true

    local release_id
    release_id=$(github "${GITHUB_API}/jitsi/${project}/releases" -X POST -H "Content-Type: application/json" \
        -d "{\"tag_name\":\"stable/jitsi-meet_${VERSION}\",\"name\":\"${FULL_VERSION}\",\"body\":\"\"}" | jq ".id")
    github "${GITHUB_UPLOAD_API}/jitsi/${project}/releases/${release_id}/assets?name=$(basename "${chlog_file}")" \
        -X POST -H "Content-Type: text/markdown" --data-binary @"${chlog_file}"
    cd ..
}

echo "##  ${FULL_VERSION} ($(date +"%Y-%m-%d"))" > "${RELEASE_FILE}"

makeRelease jitsi-meet "${JITSI_MEET_WEB_VERSION}"
makeRelease jicofo "${JICOFO_VERSION}"
makeRelease jitsi-videobridge "${JVB_VERSION}"

rm -rf jitsi-meet-release-notes
git clone git@github.com:jitsi/jitsi-meet-release-notes.git
cd jitsi-meet-release-notes
git checkout -b "${FULL_VERSION}"
{ head -n 4 CHANGELOG-WEB.md; cat "${RELEASE_FILE}"; tail -n+5 CHANGELOG-WEB.md; } > CHANGELOG-WEB.md.tmp
mv CHANGELOG-WEB.md.tmp CHANGELOG-WEB.md
git commit -am "Autogenerated release notes for ${FULL_VERSION}"
git push origin "${FULL_VERSION}"
github "${GITHUB_API}/jitsi/jitsi-meet-release-notes/pulls" -X POST -H "Content-Type: application/json" \
    -d "{\"title\":\"Release notes for ${FULL_VERSION}\",\"head\":\"${FULL_VERSION}\",\"base\":\"master\"}"
