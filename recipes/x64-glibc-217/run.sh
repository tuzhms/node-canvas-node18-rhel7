#!/usr/bin/env bash

set -e
set -x

release_urlbase="$1"
disttype="$2"
customtag="$3"
datestring="$4"
commit="$5"
fullversion="v18.20.5"
source_url="$7"
source_urlbase="$8"
config_flags=""

cd /home/node

tar -xzf node.tar.gz

# configuring cares correctly to not use sys/random.h on this target
cd "node-${fullversion}"/deps/cares
sed -i 's/define HAVE_SYS_RANDOM_H 1/undef HAVE_SYS_RANDOM_H/g' ./config/linux/ares_config.h
sed -i 's/define HAVE_GETRANDOM 1/undef HAVE_GETRANDOM/g' ./config/linux/ares_config.h

# fix https://github.com/c-ares/c-ares/issues/850
if [[ "$(grep -o 'ARES_VERSION_STR "[^"]*"' ./include/ares_version.h | awk '{print $2}' | tr -d '"')" == "1.33.0" ]]; then
  sed -i 's/MSG_FASTOPEN/TCP_FASTOPEN_CONNECT/g' ./src/lib/ares__socket.c
fi

cd /home/node

cd "node-${fullversion}"

export CC="ccache gcc"
export CXX="ccache g++"
export MAJOR_VERSION=$(echo ${fullversion} | cut -d . -f 1 | tr --delete v)

. /opt/rh/devtoolset-12/enable
. /opt/rh/rh-python38/enable

./configure
make -j$(getconf _NPROCESSORS_ONLN)

# mv node-*.tar.?z /out/
export PATH="$PATH:/home/node/node-v18.20.5/out/Release/"

node --version

curl -qL https://www.npmjs.com/install.sh | sh

node out/bin/npm i -g npm@9.9.4

node out/bin/npm --version

node out/bin/npm install canvas@2.11.2 --build-from-source

cd node_modules/canvas/build/

ldd Release/canvas.node | awk '{print $3}' | grep -E '^/lib64/*' | xargs -I {} cp {} Release/

tar -czf "/home/node/canvas-v2.11.2-node-v108-linux-glibc-x64.tar.gz" -C . Release/
tar -tvf /home/node/canvas-v2.11.2-node-v108-linux-glibc-x64.tar.gz