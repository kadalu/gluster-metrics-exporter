#!/bin/sh -eu

# Based on https://gist.github.com/j8r/34f1a344336901960c787517b5b6d616

LOCAL_PROJECT_PATH=${1-$PWD}
VERSION=`shards version`
CMDS="
echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >>/etc/apk/repositories
apk add --update --no-cache --force-overwrite \
    crystal@edge \
    gc-dev gcc gmp-dev libatomic_ops libevent-static musl-dev pcre-dev \
    libxml2-dev openssl-dev openssl-libs-static tzdata yaml-dev zlib-static \
    make git \
    llvm10-dev llvm10-static g++ \
    shards@edge \
    yaml-static
shards install --production
shards update
VERSION=${VERSION} time -v shards build --static --release --stats --time
chown 1000:1000 -R bin
mv bin/gluster-metrics-exporter bin/gluster-metrics-exporter-arm64
"

# Compile Crystal project statically for arm64 (aarch64)
docker pull multiarch/qemu-user-static:register
docker run --rm --privileged multiarch/qemu-user-static:register --reset
docker run -it -v $LOCAL_PROJECT_PATH:/workspace -w /workspace --rm multiarch/alpine:aarch64-latest-stable /bin/sh -c "$CMDS"
