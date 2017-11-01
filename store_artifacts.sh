#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x

echo "xfer contains:"
ls -l /xfer
echo "docker contains:"
ls -l /xfer/docker

COMMIT_TAG="unknown"
VERSION_FILE="istio.commit.txt"
BUILD_TYPE="daily"

DAY_PATH=`TZ=:America/Los_Angeles date +%Y%m%d`
#DAY_PATH=`TZ=:UTC date +%Y%m%d`
PROJECT_NAME="istio-testing"
BRANCH_NAME="unknown"
ARTIFACTS_OUTPUT_PATH=""
PATH_SUFFIX=""

function usage() {
  echo "$0
    -b <name> name of branch
    -c        continuous (per-submit) build rather than daily
    -d        daily build (default)
    -o        path to store build artifacts instead of GCS/GCR/docker
    -p        specifies project name (default $PROJECT_NAME)
    -s <hash> sha1 commit hash of change
    -x        extra path suffix at end"
  exit 1
}

while getopts b:cdo:p:s:x: arg ; do
  case "${arg}" in
    b) BRANCH_NAME="${OPTARG}";;
    c) BUILD_TYPE="continuous";;
    d) ;;
    o) ARTIFACTS_OUTPUT_PATH="${OPTARG}";;
    p) PROJECT_NAME="${OPTARG}";;
    s) COMMIT_TAG="${OPTARG}";;
    x) PATH_SUFFIX="${OPTARG}";;
    *) usage;;
  esac
done

if [[ "${BUILD_TYPE}" == "daily" ]]; then
  if [[ "${BRANCH_NAME}" == "unknown" ]]; then
    echo "Branch name (-b option) required for a daily build"
    usage
    exit 1
  fi
  COMMON_URI_SUFFIX="${PROJECT_NAME}/daily/${BRANCH_NAME}/${DAY_PATH}${PATH_SUFFIX}"
else
  if [[ "${COMMIT_TAG}" == "unknown" ]]; then
    echo "Commit hash (-s option) required when continuous build is requested via -c"
    usage
    exit 1
  fi
  COMMON_URI_SUFFIX="${PROJECT_NAME}/continuous/${COMMIT_TAG}${PATH_SUFFIX}"
fi

GCS_PATH="gs://${COMMON_URI_SUFFIX}"
GCR_PATH="gcr.io/${COMMON_URI_SUFFIX}"

gsutil -m cp -r "${ARTIFACTS_OUTPUT_PATH}/*" "${GCS_PATH}/"

for TAR_PATH in "${ARTIFACTS_OUTPUT_PATH}/docker/*.tar"
do
  TAR_NAME=$(basename "$TAR_PATH")
  IMAGE_NAME="${TAR_NAME%.*}"
  echo converting "${TAR_PATH}" to "${IMAGE_NAME}"
  docker import "${TAR_PATH}" "${IMAGE_NAME}:0.0.0"
  docker images
  docker tag "${IMAGE_NAME}:0.0.0" "${GCR_PATH}/${IMAGE_NAME}:0.0.0"
  gcloud docker -- push "${GCR_PATH}/${IMAGE_NAME}:0.0.0"
done

echo "${COMMIT_TAG}" > "${VERSION_FILE}"
gsutil cp "${VERSION_FILE}" "${GCS_PATH}/"
