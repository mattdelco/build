#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x

MANIFEST_REPO_URL=""
MANIFEST_FILE="default.xml"

function usage() {
  echo "$0
    -m <file>  name of manifest in repo (optional, defaults to default.xml)
    -u <url>   url for git repo containing manifest"
  exit 1
}

while getopts m:u: arg ; do
  case "${arg}" in
    m) MANIFEST_FILE="${MANIFEST_FILE}";;
    u) MANIFEST_REPO_URL="${OPTARG}";;
    *) usage;;
  esac
done

[[ -z "${MANIFEST_REPO_URL}" ]] && usage

./repo init -u "${MANIFEST_REPO_URL}" -m "${MANIFEST_FILE}"
./repo sync
