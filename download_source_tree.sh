#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x

mkdir manifest
cp ./default.xml manifest/
pushd manifest
git init
git add default.xml
# git commit insists on "Please tell me who you are."
git config user.email "root@localhost"
git config user.name "root"
git commit -m "local manifest"
popd
./repo init -u ./manifest
./repo sync

#mkdir /source/auth
#mkdir /source/auth/bin
#mkdir /source/mixer
#mkdir /source/mixer/bin
#mkdir /source/pilot
#mkdir /source/pilot/bin
#mkdir /source/proxy
#mkdir /source/proxy/script

#for BUILD_FILE in /source/auth/bin/daily_cloud_builder.sh /source/mixer/bin/daily_cloud_builder.sh /source/pilot/bin/daily_cloud_builder.sh /source/proxy/script/daily_cloud_builder.sh /source/store_artifacts.sh
#do
#  echo "#!/bin/bash" > $BUILD_FILE
#  RESULT_FILE="$(basename ${BUILD_FILE}).results"
#  echo "touch /xfer/${RESULT_FILE}" >> $BUILD_FILE
#  echo "ls -l /xfer" >> $BUILD_FILE
#  chmod u+x $BUILD_FILE
#done
