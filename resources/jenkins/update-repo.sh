#!/bin/bash

# Processes the mini-dinstall incoming dir once.

set -e -u

: "${REPO_DIR:?REPO_DIR must be set}"
: "${MINID_CONF_FILE:?MINID_CONF_FILE must be set}"

mini-dinstall -b -c "${MINID_CONF_FILE}" "${REPO_DIR}"
