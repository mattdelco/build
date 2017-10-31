#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x

echo "Workspace contains:"
ls -l /workspace/*
echo "xfer contains:"
ls -l /xfer

COMMIT_TAG="unknown"
VERSION_FILE="istio.commit.txt"
BUILD_TYPE="daily"

DAY_PATH=`date +%Y%m%d`
PROJECT_NAME="istio-testing"
BRANCH_NAME="unknown"
ARTIFACTS_OUTPUT_PATH=""

function usage() {
  echo "$0
    -b <name> name of branch
    -c        continuous (per-submit) build rather than daily
    -d        daily build (default)
    -o        path to store build artifacts instead of GCS/GCR/docker
    -p        specifies project name (default $PROJECT_NAME)
    -s <hash> sha1 commit hash of change"
  exit 1
}

while getopts b:cdo:p:s: arg ; do
  case "${arg}" in
    b) BRANCH_NAME="${OPTARG}";;
    c) BUILD_TYPE="continuous";;
    d) ;;
    o) ARTIFACTS_OUTPUT_PATH="${OPTARG}";;
    p) PROJECT_NAME="${OPTARG}";;
    s) COMMIT_TAG="${OPTARG}";;
    *) usage;;
  esac
done

if [[ "${BUILD_TYPE}" == "daily" ]]; then
  if [[ "${BRANCH_NAME}" == "unknown" ]]; then
    echo "Branch name (-b option) required for a daily build"
    usage
    exit 1
  fi
  COMMON_URI_SUFFIX="${PROJECT_NAME}/daily/${BRANCH_NAME}/${DAY_PATH}_xfer"
else
  if [[ "${COMMIT_TAG}" == "unknown" ]]; then
    echo "Commit hash (-s option) required when continuous build is requested via -c"
    usage
    exit 1
  fi
  COMMON_URI_SUFFIX="${PROJECT_NAME}/continuous/${COMMIT_TAG}_xfer"
fi

GCS_PATH="gs://${COMMON_URI_SUFFIX}"
# GCR_PATH="gcr.io/${COMMON_URI_SUFFIX}"

gsutil -m cp -r "${ARTIFACTS_OUTPUT_PATH}/*" "${GCS_PATH}/"

echo "${COMMIT_TAG}" > "${VERSION_FILE}"
gsutil cp "${VERSION_FILE}" "${GCS_PATH}/"
