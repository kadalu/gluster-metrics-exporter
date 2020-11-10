#!/bin/bash
time docker run --rm -it -v $PWD:/workspace -w /workspace crystallang/crystal:0.35.1-alpine /bin/sh -c 'shards install --production && shards build --release --static'
