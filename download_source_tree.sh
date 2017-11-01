#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x

MANIFEST_REPO_URL=""
MANIFEST_BRANCH="master"
MANIFEST_FILE="default.xml"

function usage() {
  echo "$0
    -b <branch>  branch to use in manifest (optional, defaults to master)
    -m <file>    name of manifest in repo (optional, defaults to default.xml)
    -u <url>     url for git repo containing manifest"
  exit 1
}

while getopts b:m:u: arg ; do
  case "${arg}" in
    b) MANIFEST_BRANCH="${OPTARG}";;
    m) MANIFEST_FILE="${OPTARG}";;
    u) MANIFEST_REPO_URL="${OPTARG}";;
    *) usage;;
  esac
done

[[ -z "${MANIFEST_REPO_URL}" ]] && usage

./repo init -u "${MANIFEST_REPO_URL}" -m "${MANIFEST_FILE}" -b "${MANIFEST_BRANCH}"
./repo sync
