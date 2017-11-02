#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x

DONE_FILE="istio.done.txt"
VERSION_FILE=""

GC_BUCKET=""
GC_SUBDIR="builds/unknown"
VER_STRING=""
OUTPUT_PATH=""
VERSION_FILE=""
BUILD_ID=""

function usage() {
  echo "$0
    -d <file> name of file to create to signal completion       (optional, default ${DONE_FILE})
    -f <file> name of file to use for contents of -d            (optional, empty file if not set)
    -i <id>   build ID from cloud builder                       (optional, currently unused)
    -o <path> path where build output/artifacts were stored     (required)
    -p <name> specifies GCS/GCR bucket to store build           (required)
    -s <path> path to store build on GCS/GCR (-v is appended)   (optional, default ${GC_SUBDIR})
    -v <ver>  version string (appended to -? option)            (required)"
  exit 1
}

while getopts f:i:o:p:s:v: arg ; do
  case "${arg}" in
    f) VERSION_FILE="${OPTARG}";;
    i) BUILD_ID="${OPTARG}";;
    o) OUTPUT_PATH="${OPTARG}";;
    p) GC_BUCKET="${OPTARG}";;
    s) GC_SUBDIR="${OPTARG}";;
    v) VER_STRING="${OPTARG}";;
    *) usage;;
  esac
done

[[ -z "${OUTPUT_PATH}"  ]] && usage
[[ -z "${GC_BUCKET}"    ]] && usage
[[ -z "${VER_STRING}"   ]] && usage

COMMON_URI_SUFFIX="${GC_BUCKET}/${GC_SUBDIR}/${VER_STRING}"
GCS_PATH="gs://${COMMON_URI_SUFFIX}"
GCR_PATH="gcr.io/${COMMON_URI_SUFFIX}"

gsutil -m cp -r "${OUTPUT_PATH}/*" "${GCS_PATH}/"

for TAR_PATH in ${OUTPUT_PATH}/docker/*.tar
do
  TAR_NAME=$(basename "$TAR_PATH")
  IMAGE_NAME="${TAR_NAME%.*}"

  # if no docker/ directory or directory has no tar files
  if [[ "${IMAGE_NAME}" == "*" ]]; then
    break
  fi
  docker import "${TAR_PATH}" "${IMAGE_NAME}:${VER_STRING}"
  docker tag "${IMAGE_NAME}:${VER_STRING}" "${GCR_PATH}/${IMAGE_NAME}:${VER_STRING}"
  gcloud docker -- push "${GCR_PATH}/${IMAGE_NAME}:${VER_STRING}"
done

if [[ "${VERSION_FILE}" != "" ]]; then
  cp "${OUTPUT_PATH}/${VERSION_FILE}" "${DONE_FILE}"
else
  touch "${DONE_FILE}"  
fi
gsutil cp "${DONE_FILE}" "${GCS_PATH}/"

echo "Build completed"
