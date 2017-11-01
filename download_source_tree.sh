#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x

MANIFEST_REPO_URL=""
MANIFEST_BRANCH="master"
MANIFEST_FILE="default.xml"
BUILD_ID="unknown"
PRODUCT_VERSION="0.0.0"
ARTIFACTS_OUTPUT_PATH=""
VERSION_FILE=""

function usage() {
  echo "$0
    -b <branch>  branch to use in manifest (optional, defaults to $MANIFEST_BRANCH)
    -i <id>      unique identier of build (optional, defaults to $BUILD_ID)
    -m <file>    name of manifest in repo (optional, defaults to $MANIFEST_FILE)
    -o <path>    path where build artifacts are stored     
    -u <url>     url for git repo containing manifest
    -v <name>    name of version file to generate in output dir (optional)"
  exit 1
}

while getopts b:i:m:o:u:v: arg ; do
  case "${arg}" in
    b) MANIFEST_BRANCH="${OPTARG}";;
    i) BUILD_ID="${OPTARG}";;
    m) MANIFEST_FILE="${OPTARG}";;
    o) ARTIFACTS_OUTPUT_PATH="${OPTARG}";;
    u) MANIFEST_REPO_URL="${OPTARG}";;
    v) VERSION_FILE="${OPTARG}";;
    *) usage;;
  esac
done

[[ -z "${MANIFEST_REPO_URL}" ]] && usage
[[ -z "${ARTIFACTS_OUTPUT_PATH}" ]] && usage

./repo init -u "${MANIFEST_REPO_URL}" -m "${MANIFEST_FILE}" -b "${MANIFEST_BRANCH}"
./repo sync

# copy over repo's manifest file to assist reproducibility
cp .repo/manifest.xml "${ARTIFACTS_OUTPUT_PATH}/"

# TO-DO: read/determine product version
# As of Nov 1 the spec says:
# echo "$(cat istio.VERSION)-$(date '+%Y%m%d')-$(repo manifest -r | sha256sum | head -c 10)"
# 0.3.0-20171027-d324edf901
# though current istio.VERSION has hashes of components (for FORTIO_TAG is 0.2.7)

if [[ "${VERSION_FILE}" != "" ]]; then
  VERSION_PATH="${ARTIFACTS_OUTPUT_PATH}/${VERSION_FILE}"
  echo "version $PRODUCT_VERSION" >  "${VERSION_PATH}"
  echo "build   $BUILD_ID"        >> "${VERSION_PATH}"
fi
