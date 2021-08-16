#!/bin/bash
VERSION=`shards version`
CMDS="
time -v shards install --production
shards update
VERSION=${VERSION} time -v shards build --static --release --stats --time
mv bin/gluster-metrics-exporter bin/gluster-metrics-exporter-amd64
"

docker run --rm -it -v $PWD:/workspace -w /workspace crystallang/crystal:1.1.1-alpine /bin/sh -c "$CMDS"
