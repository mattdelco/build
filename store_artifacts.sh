#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x

DONE_FILE="istio.done.txt"
VERSION_FILE=""

DAY_PATH=`TZ=:America/Los_Angeles date +%Y%m%d`
#DAY_PATH=`TZ=:UTC date +%Y%m%d`
GC_BUCKET="istio-testing"
BRANCH_NAME="unknown"
ARTIFACTS_OUTPUT_PATH=""
PATH_SUFFIX=""

function usage() {
  echo "$0
    -b <name> name of branch (default is $BRANCH_NAME)
    -o <path> path where build artifacts were stored
    -p <name> specifies GCS/GCR bucket (default is $GC_BUCKET)
    -v <name> name of version file to use in output dir (optional)"
  exit 1
}

while getopts b:o:p:v: arg ; do
  case "${arg}" in
    b) BRANCH_NAME="${OPTARG}";;
    o) ARTIFACTS_OUTPUT_PATH="${OPTARG}";;
    p) GC_BUCKET="${OPTARG}";;
    v) VERSION_FILE="${OPTARG}";;
    *) usage;;
  esac
done

[[ -z "${ARTIFACTS_OUTPUT_PATH}" ]] && usage

COMMON_URI_SUFFIX="${GC_BUCKET}/daily/${BRANCH_NAME}/${DAY_PATH}"
GCS_PATH="gs://${COMMON_URI_SUFFIX}"
GCR_PATH="gcr.io/${COMMON_URI_SUFFIX}"

gsutil -m cp -r "${ARTIFACTS_OUTPUT_PATH}/*" "${GS_PATH}/"

# TO-DO: read version from file
BUILD_VERSION="0.0.0"
for TAR_PATH in ${ARTIFACTS_OUTPUT_PATH}/docker/*.tar
do
  TAR_NAME=$(basename "$TAR_PATH")
  IMAGE_NAME="${TAR_NAME%.*}"
  docker import "${TAR_PATH}" "${IMAGE_NAME}:${BUILD_VERSION}"
  docker tag "${IMAGE_NAME}:${BUILD_VERSION}" "${GCR_PATH}/${IMAGE_NAME}:${BUILD_VERSION}"
  gcloud docker -- push "${GCR_PATH}/${IMAGE_NAME}:${BUILD_VERSION}"
done

if [[ "${VERSION_FILE}" != "" ]]; then
  cp "${ARTIFACTS_OUTPUT_PATH}/${VERSION_FILE}" "${DONE_FILE}"
else
  touch "${DONE_FILE}"  
fi
gsutil cp "${DONE_FILE}" "${GCS_PATH}/"
