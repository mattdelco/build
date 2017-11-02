#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x

MANIFEST_URL=""
VER_STRING=""
BUILD_ID=""
OUTPUT_PATH=""
VERSION_FILE="version.txt"

function usage() {
  echo "$0
    -f <file> name of version file to generate in -o dir        (optional, default ${VERSION_FILE} )
    -i <id>   build ID from cloud builder                       (optional)
    -o <path> path where build output/artifacts were stored     (required)
    -u <url>  URL to xml file with manifest to use with repo    (required)
    -v <ver>  version string (MUST be lowercase letters)        (required)"
  exit 1
}

while getopts f:i:o:u:v: arg ; do
  case "${arg}" in
    f) VERSION_FILE="${OPTARG}";;
    i) BUILD_ID="${OPTARG}";;
    o) OUTPUT_PATH="${OPTARG}";;
    u) MANIFEST_URL="${OPTARG}";;
    v) VER_STRING="${OPTARG}";;
    *) usage;;
  esac
done

[[ -z "${VERSION_FILE}" ]] && usage
[[ -z "${MANIFEST_URL}" ]] && usage
[[ -z "${OUTPUT_PATH}" ]] && usage
[[ -z "${VER_STRING}"   ]] && usage

VER_STRING_LOWER=${VER_STRING,,}

if [[ "$VER_STRING" != "$VER_STRING_LOWER" ]]; then
  echo "ERROR: version string can not have uppercase letters"
  usage
fi

# download specified manifest and add it to a temp
# repo since repo can't seem to handle a plain file

TEMP_REPO="temp_manifest"
MFEST_XML="default.xml"
mkdir "$TEMP_REPO"
# github likes using directs so using -L to follow them
curl -L "$MANIFEST_URL" > "${TEMP_REPO}/${MFEST_XML}"
pushd "$TEMP_REPO"
git init
git add $MFEST_XML
# git insists on knowing the ID of the submitter
git config user.name  "root"
git config user.email "root@localhost"
git commit -m "temp default manifest"
popd
./repo init -u "$TEMP_REPO"
#./repo init -u "${MANIFEST_REPO_URL}" -m "${MANIFEST_FILE}" -b "${MANIFEST_BRANCH}"
./repo sync

# copy over repo's manifest file to assist reproducibility
cp .repo/manifest.xml "${OUTPUT_PATH}/"

VERSION_PATH="${OUTPUT_PATH}/${VERSION_FILE}"

# output.version is used to help store_artifacts.sh diffentiate
# between current vs. older branches
echo "output.version=1"          > "$VERSION_PATH"
echo "version=$VER_STRING"       >> "$VERSION_PATH"
echo "buildID=$BUILD_ID"         >> "$VERSION_PATH"
echo "manifestURL=$MANIFEST_URL" >> "$VERSION_PATH"
